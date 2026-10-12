# frozen_string_literal: true

#
# Subject Map index generator
#
# Reads the tag/term list in _data/subject-map.csv and every transcript in
# _data/transcripts/, then at build time:
#
#   1. writes one JSON file per tag to assets/data/subject-map/<tag-slug>.json,
#      holding every tagged passage for that tag's terms (with five words of
#      context either side) plus the interview titles from the metadata CSV;
#   2. exposes site.data.subject_map (tags, terms, passage counts) so the
#      Liquid tree on /subject-map.html can render without any JavaScript.
#
# A transcript row counts as a passage for a term when the term appears in the
# row's "terms" column (e.g. "doctor;horse;potlatch"). Transcripts with no
# "terms" column fall back to a word-boundary text search, which is slower.
#
# Optional settings in _data/theme.yml (defaults shown):
#   subject-map-data: subject-map
#   subject-map-transcripts: transcripts
#   subject-map-speaker-field: speaker
#   subject-map-timestamp-field: timestamp
#   subject-map-words-field: words
#   subject-map-terms-field: terms
#   subject-map-context-words: 5
#   subject-map-output: assets/data/subject-map
#

require 'json'
require 'fileutils'

module SubjectMap
  # Order of the values in each passage array written to the JSON files.
  FIELDS = %w[objectid line timestamp seconds speaker before match after found].freeze

  # A file generated in memory and written straight to _site, skipping Liquid
  # (transcript text could otherwise contain "{{" and break the build).
  class GeneratedFile < Jekyll::StaticFile
    def initialize(site, dir, name, content)
      super(site, site.source, dir, name)
      @generated_content = content
    end

    def write(dest)
      dest_path = destination(dest)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, @generated_content)
      true
    end

    def modified?
      true
    end

    def mtime
      Time.now.to_i
    end

    def modified_time
      Time.now
    end
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    DEFAULTS = {
      'subject-map-data' => 'subject-map',
      'subject-map-transcripts' => 'transcripts',
      'subject-map-speaker-field' => 'speaker',
      'subject-map-timestamp-field' => 'timestamp',
      'subject-map-words-field' => 'words',
      'subject-map-terms-field' => 'terms',
      'subject-map-context-words' => 5,
      'subject-map-output' => 'assets/data/subject-map'
    }.freeze

    def generate(site)
      theme = site.data['theme'].is_a?(Hash) ? site.data['theme'] : {}
      @cfg = DEFAULTS.merge(theme.select { |key, value| DEFAULTS.key?(key) && !value.nil? })
      @context = @cfg['subject-map-context-words'].to_i

      rows = site.data[@cfg['subject-map-data']]
      unless rows.is_a?(Array)
        Jekyll.logger.warn 'Subject Map:', "_data/#{@cfg['subject-map-data']}.csv not found, skipping."
        return
      end

      tags = parse_tags(rows)
      lookup = build_lookup(tags)
      occurrences = Hash.new { |hash, key| hash[key] = [] }

      transcripts = site.data[@cfg['subject-map-transcripts']]
      transcripts = {} unless transcripts.is_a?(Hash)
      transcripts.keys.sort.each do |objectid|
        index_transcript(objectid.to_s, transcripts[objectid], lookup, occurrences)
      end

      publish(site, tags, occurrences, load_titles(site))
    end

    private

    # ---- tag list -----------------------------------------------------------

    def parse_tags(rows)
      rows.filter_map do |row|
        name = row['tag'].to_s.strip
        next if name.empty?

        raw = row['terms'].to_s.split(';').map(&:strip).reject(&:empty?)
        raw.select { |term| term.include?(':') }.each do |term|
          Jekyll.logger.warn 'Subject Map:', "\"#{term}\" in #{name} contains a colon. Should it be a semicolon?"
        end
        terms = raw.uniq { |term| normalize(term) }
                   .map { |term| { 'label' => term, 'key' => normalize(term) } }

        {
          'tag' => name,
          'slug' => Jekyll::Utils.slugify(name),
          'description' => row['description'].to_s.strip,
          'terms' => terms
        }
      end
    end

    def normalize(text)
      text.to_s.unicode_normalize(:nfkc).tr("‘’ʼ", "'").downcase.gsub(/\s+/, ' ').strip
    end

    # key => regexps used to locate the term inside a line of dialogue
    def build_lookup(tags)
      tags.flat_map { |tag| tag['terms'].map { |term| term['key'] } }.uniq
          .to_h { |key| [key, patterns_for(key)] }
    end

    def patterns_for(key)
      variants = [key]
      variants << key.split(',').first.strip if key.include?(',') # "troy, idaho" -> "troy"
      variants.uniq.reject(&:empty?).map do |variant|
        body = Regexp.escape(variant).gsub('\\ ') { '\\s+' }.gsub("'") { "['’]" }
        Regexp.new("(?<![[:alnum:]])#{body}(?:['’]?s|es)?(?![[:alnum:]])", Regexp::IGNORECASE)
      end
    end

    # ---- transcripts --------------------------------------------------------

    def index_transcript(objectid, rows, lookup, occurrences)
      return unless rows.is_a?(Array) && rows.first.is_a?(Hash)

      words_field = @cfg['subject-map-words-field']
      terms_field = @cfg['subject-map-terms-field']
      tagged = rows.first.key?(terms_field)
      unless tagged
        Jekyll.logger.warn 'Subject Map:', "#{objectid} has no \"#{terms_field}\" column, using text search."
      end

      rows.each_with_index do |row, index|
        words = row[words_field].to_s
        next if words.strip.empty?

        keys = if tagged
                 row[terms_field].to_s.split(';').map { |term| normalize(term) }
                                 .reject(&:empty?).uniq.select { |key| lookup.key?(key) }
               else
                 lookup.keys.select { |key| lookup[key].any? { |re| re.match?(words) } }
               end

        keys.each { |key| occurrences[key] << passage(objectid, index, row, words, lookup[key]) }
      end
    end

    def passage(objectid, index, row, words, patterns)
      timestamp = row[@cfg['subject-map-timestamp-field']].to_s.strip
      speaker = row[@cfg['subject-map-speaker-field']].to_s.strip
      before, match, after, found = snippet(words, patterns)
      [objectid, index, timestamp, to_seconds(timestamp), speaker, before, match, after, found ? 1 : 0]
    end

    # Returns [text before, matched term, text after, found?] with
    # @context words either side of the term.
    def snippet(text, patterns)
      tokens = []
      text.scan(/\S+/) { tokens << [Regexp.last_match.begin(0), Regexp.last_match.end(0)] }

      match = nil
      patterns.each do |re|
        match = re.match(text)
        break if match
      end

      # Tagged, but the word itself isn't in the line: show the opening words.
      unless match
        last = [tokens.length, (@context * 2) + 1].min - 1
        lead = squish(text[tokens[0][0]...tokens[last][1]])
        lead += ' …' if last < tokens.length - 1
        return [lead, '', '', false]
      end

      start = match.begin(0)
      finish = match.end(0)
      first_token = tokens.index { |(_, stop)| stop > start }
      last_token = tokens.rindex { |(begin_at, _)| begin_at < finish }
      from = [first_token - @context, 0].max
      to = [last_token + @context, tokens.length - 1].min

      before = squish(text[tokens[from][0]...start])
      after = squish(text[finish...tokens[to][1]])
      before = "… #{before}" if from.positive?
      after = "#{after} …" if to < tokens.length - 1
      [before, match[0], after, true]
    end

    def squish(text)
      text.to_s.gsub(/\s+/, ' ')
    end

    def to_seconds(timestamp)
      parts = timestamp.split(':')
      return nil if parts.empty? || parts.any? { |part| part !~ /\A\d+(\.\d+)?\z/ }

      parts.map(&:to_f).reduce(0) { |total, part| (total * 60) + part }.round
    end

    # ---- output -------------------------------------------------------------

    def load_titles(site)
      metadata = site.data[site.config['metadata'].to_s]
      return {} unless metadata.is_a?(Array)

      metadata.each_with_object({}) do |row, titles|
        id = row['objectid'].to_s.strip
        titles[id] = row['title'].to_s.strip unless id.empty?
      end
    end

    def publish(site, tags, occurrences, titles)
      out_dir = @cfg['subject-map-output'].to_s.sub(%r{\A/}, '')
      passages = 0

      tags.each do |tag|
        terms = {}
        tag['terms'].each do |term|
          list = occurrences.fetch(term['key'], [])
          term['count'] = list.size
          term['interviews'] = list.map(&:first).uniq.size
          terms[term['key']] = list unless list.empty?
        end
        tag['count'] = tag['terms'].sum { |term| term['count'] }
        passages += tag['count']

        ids = terms.values.flatten(1).map(&:first).uniq
        payload = {
          'tag' => tag['tag'],
          'fields' => FIELDS,
          'titles' => ids.to_h { |id| [id, titles[id].to_s.empty? ? id : titles[id]] },
          'terms' => terms
        }
        site.static_files << GeneratedFile.new(site, out_dir, "#{tag['slug']}.json", JSON.generate(payload))
      end

      site.data['subject_map'] = tags
      Jekyll.logger.info 'Subject Map:', "#{passages} passages indexed across #{tags.size} tags."
    end
  end
end
