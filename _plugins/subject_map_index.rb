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
# _data/subject-map.csv columns: domain, tag, group, terms (a description column is optional and unused).
# "domain" is optional; it groups tags under Culture, Labor ... (several with " | ").
# "group" is optional; nest sections with " > ", e.g. "Animals > Birds".
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
#   subject-map-item-path: people   (folder of interview pages; auto-detected from page_gen)
#   subject-map-match: auto         (auto | tagged | text | both, see plan_matching)
#
# A folded term gathers several names under one entry:
#   "Ku Klux Klan = Klan"   or   "Indigenous = Camas Prairie | Coos | Nez Perce"
# Its passages are every line that mentions the label or any alias.
# A name with a leading minus is excluded instead, matching exactly as typed
# (case-sensitive):
#   "British = England | London | -British Columbia"
# leaves out lines where "British" appears only as part of "British Columbia";
#   "Chinese = China | Hong Kong | -china"  drops "china" (dishes), keeps "China".
#
# A definition follows the first colon: "Marions: Brand of logging equipment".
# It appears only in the term's modal, after the title.
#
# A term label may carry a display-only note in brackets: "Boise (Ada County)"
# is shown as written but matched in the transcripts as "Boise".
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
      'subject-map-output' => 'assets/data/subject-map',
      'subject-map-match' => 'auto'
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
      @exclusions = build_exclusions(tags)
      occurrences = Hash.new { |hash, key| hash[key] = [] }

      transcripts = site.data[@cfg['subject-map-transcripts']]
      transcripts = {} unless transcripts.is_a?(Hash)
      plan_matching(transcripts, lookup)
      transcripts.keys.sort.each do |objectid|
        index_transcript(objectid.to_s, transcripts[objectid], lookup, occurrences)
      end

      publish(site, tags, occurrences, load_titles(site))
    end

    private

    # ---- tag list -----------------------------------------------------------

    # Each CSV row is a tag, an optional group path ("Animals > Birds") and its
    # terms. Rows for the same tag are merged in file order. Each tag gets:
    #   'terms'    - flat list of unique terms (used for indexing and counts)
    #   'children' - display tree of groups ({'group' => true, 'name', 'children'})
    #                and terms, in the order they appear in the CSV
    def parse_tags(rows)
      tags = {}
      rows.each do |row|
        name = row['tag'].to_s.strip
        next if name.empty?

        tag = tags[name] ||= {
          'tag' => name,
          'slug' => Jekyll::Utils.slugify(name),
          'description' => row['description'].to_s.strip,
          'domains' => [],
          'terms' => [],
          'children' => [],
          'by_key' => {}
        }

        # Optional top-level domain(s) the tag sits under; "Infrastructure | Labor" lists it twice.
        row['domain'].to_s.split('|').map(&:strip).reject(&:empty?).each do |domain|
          tag['domains'] << domain unless tag['domains'].include?(domain)
        end

        container = tag['children']
        row['group'].to_s.split('>').map(&:strip).reject(&:empty?).each do |part|
          group = container.find { |node| node['group'] && node['name'] == part }
          unless group
            group = { 'group' => true, 'name' => part, 'children' => [] }
            container << group
          end
          container = group['children']
        end

        raw = row['terms'].to_s.split(';').map(&:strip).reject(&:empty?)
        raw.each do |entry|
          # "Label = alias | alias: definition" - the definition (after the first
          # colon) is shown only in the term's modal, after its title.
          head, definition = entry.split(':', 2).map(&:strip)
          label, folded = head.to_s.split('=', 2).map(&:strip)
          next if label.to_s.empty?

          aliases = folded.to_s.split('|').map(&:strip).reject(&:empty?)
          key = normalize(match_text(label))
          term = tag['by_key'][key]
          unless term
            term = { 'label' => label, 'key' => key, 'match_keys' => [key] }
            tag['by_key'][key] = term
            tag['terms'] << term
          end
          term['definition'] = definition if definition && !definition.empty? && !term['definition']
          # Folded term: "Label = alias | alias" gathers the passages of every alias.
          aliases.each do |alias_label|
            # "-British Columbia": lines where the term appears only inside this
            # phrase are left out of the term's passages.
            if alias_label.start_with?('-')
              phrase = alias_label.sub(/\A-\s*/, '')
              (term['excludes'] ||= []) << phrase unless phrase.empty? || (term['excludes'] || []).include?(phrase)
              next
            end
            alias_key = normalize(match_text(alias_label))
            next if term['match_keys'].include?(alias_key)

            term['match_keys'] << alias_key
            (term['includes'] ||= []) << alias_label
          end
          container << term unless container.include?(term)
        end
      end
      tags.values.each { |tag| tag.delete('by_key') }
    end

    # "Boise (Ada County)" matches transcripts as "Boise"; the note is display-only.
    def match_text(label)
      label.sub(/\s*\([^()]*\)\s*\z/, '')
    end

    def normalize(text)
      text.to_s.unicode_normalize(:nfkc).tr("‘’ʼ", "'").downcase.gsub(/\s+/, ' ').strip
    end

    # key => regexps used to locate the term inside a line of dialogue
    # match key => regexps for the phrases its term excludes ("-British Columbia")
    def build_exclusions(tags)
      exclusions = Hash.new { |hash, key| hash[key] = [] }
      tags.each do |tag|
        tag['terms'].each do |term|
          patterns = Array(term['excludes']).map { |phrase| exclusion_pattern(phrase) }
          next if patterns.empty?

          term['match_keys'].each { |key| exclusions[key].concat(patterns) }
        end
      end
      exclusions.default_proc = nil
      exclusions
    end

    # Blank out excluded phrases (same length, so positions still line up).
    def mask_excluded(words, key)
      Array(@exclusions[key]).reduce(words) { |text, re| text.gsub(re) { |m| ' ' * m.length } }
    end

    def build_lookup(tags)
      tags.flat_map { |tag| tag['terms'].flat_map { |term| term['match_keys'] } }.uniq
          .to_h { |key| [key, patterns_for(key)] }
    end

    # Exclusions match exactly as typed (case-sensitive), so "-china" removes the
    # dishes but keeps "China"; "-British Columbia" leaves "british" alone.
    def exclusion_pattern(phrase)
      text = phrase.to_s.unicode_normalize(:nfkc).tr("\u2018\u2019\u02BC", "'").gsub(/\s+/, ' ').strip
      body = Regexp.escape(text).gsub('\\ ') { '\\s+' }.gsub("'") { "['\u2019]" }
      Regexp.new("(?<![[:alnum:]])#{body}(?:['\u2019]?s|es)?(?![[:alnum:]])")
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

    # How each term is found in the transcripts ("subject-map-match" in theme.yml):
    #   auto   - terms that appear in any transcript's terms column use those tags;
    #            terms never tagged anywhere (newly added ones) are found by
    #            searching the dialogue for the word itself  (default)
    #   tagged - terms column only
    #   text   - dialogue search only
    #   both   - terms column plus dialogue search for every term
    def plan_matching(transcripts, lookup)
      mode = @cfg['subject-map-match'].to_s.strip.downcase
      terms_field = @cfg['subject-map-terms-field']
      @use_column = mode != 'text'

      tagged = {}
      if mode == 'auto'
        transcripts.each_value do |rows|
          next unless rows.is_a?(Array)

          rows.each do |row|
            next unless row.is_a?(Hash)

            row[terms_field].to_s.split(';').each do |term|
              key = normalize(term)
              tagged[key] = true if lookup.key?(key)
            end
          end
        end
      end

      text_keys = case mode
                  when 'tagged' then []
                  when 'text', 'both' then lookup.keys
                  else lookup.keys.reject { |key| tagged[key] }
                  end
      @text_index = first_word_index(text_keys, lookup)
      @full_index = first_word_index(lookup.keys, lookup)
      unless text_keys.empty? || mode != 'auto'
        Jekyll.logger.info 'Subject Map:', "#{text_keys.size} terms not in any terms column, searching dialogue for them."
      end
    end

    # first word of each term variant => keys, so a line is only tested
    # against the few terms that could start at one of its words
    def first_word_index(keys, lookup)
      index = Hash.new { |hash, word| hash[word] = [] }
      keys.each do |key|
        variants = [key]
        variants << key.split(',').first.strip if key.include?(',')
        variants.each do |variant|
          word = variant[/[[:alnum:]]+/]
          index[word] << key if word && !index[word].include?(key)
        end
      end
      index.default_proc = nil
      index
    end

    def text_matches(words, index, lookup)
      found = []
      words.downcase.scan(/[[:alnum:]]+/).uniq.each do |token|
        [token, token.sub(/s\z/, ''), token.sub(/es\z/, '')].uniq.each do |candidate|
          (index[candidate] || []).each do |key|
            next if found.include?(key)

            found << key if lookup[key].any? { |re| re.match?(words) }
          end
        end
      end
      found
    end

    def index_transcript(objectid, rows, lookup, occurrences)
      return unless rows.is_a?(Array) && rows.first.is_a?(Hash)

      words_field = @cfg['subject-map-words-field']
      terms_field = @cfg['subject-map-terms-field']
      has_column = rows.first.key?(terms_field)
      unless has_column
        Jekyll.logger.warn 'Subject Map:', "#{objectid} has no \"#{terms_field}\" column, using text search."
      end

      rows.each_with_index do |row, index|
        words = row[words_field].to_s
        next if words.strip.empty?

        keys = []
        if has_column && @use_column
          keys.concat(row[terms_field].to_s.split(';').map { |term| normalize(term) }
                                       .reject(&:empty?).select { |key| lookup.key?(key) })
        end
        keys.concat(text_matches(words, has_column ? @text_index : @full_index, lookup))

        keys.uniq.each do |key|
          search = words
          if @exclusions.key?(key)
            search = mask_excluded(words, key)
            # The word is in the line, but only inside an excluded phrase: skip it.
            next if lookup[key].any? { |re| re.match?(words) } && lookup[key].none? { |re| re.match?(search) }
          end
          occurrences[key] << passage(objectid, index, row, words, lookup[key], search)
        end
      end
    end

    def passage(objectid, index, row, words, patterns, search = words)
      timestamp = row[@cfg['subject-map-timestamp-field']].to_s.strip
      speaker = row[@cfg['subject-map-speaker-field']].to_s.strip
      before, match, after, found = snippet(words, patterns, search)
      [objectid, index, timestamp, to_seconds(timestamp), speaker, before, match, after, found ? 1 : 0]
    end

    # Returns [text before, matched term, text after, found?] with
    # @context words either side of the term.
    # search: the text to look for the term in (excluded phrases blanked out);
    # same length as text, so the match positions apply to both.
    def snippet(text, patterns, search = text)
      tokens = []
      text.scan(/\S+/) { tokens << [Regexp.last_match.begin(0), Regexp.last_match.end(0)] }

      match = nil
      patterns.each do |re|
        match = re.match(search)
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
          # One passage per transcript line, even when several folded names occur in it.
          seen = {}
          list = term['match_keys'].flat_map { |key| occurrences.fetch(key, []) }
                                   .select { |o| seen[[o[0], o[1]]] ? false : (seen[[o[0], o[1]]] = true) }
                                   .sort_by { |o| [o[0], o[1]] }
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
      site.data['subject_map_item_base'] = item_base(site)
      Jekyll.logger.info 'Subject Map:', "#{passages} passages indexed across #{tags.size} tags, " \
                                         "linking to #{site.data['subject_map_item_base']}<objectid>.html"
    end

    # Folder holding the interview pages: theme.yml "subject-map-item-path" if set,
    # otherwise the "dir" of the page_gen entry for the metadata CSV, otherwise "items".
    def item_base(site)
      dir = site.data.dig('theme', 'subject-map-item-path').to_s.strip
      if dir.empty?
        generators = Array(site.config['page_gen']).select { |gen| gen.is_a?(Hash) }
        match = generators.find { |gen| gen['data'].to_s == site.config['metadata'].to_s } || generators.first
        dir = match ? match['dir'].to_s.strip : ''
      end
      dir = 'items' if dir.empty?
      "/#{dir.gsub(%r{\A/+|/+\z}, '')}/"
    end
  end
end
