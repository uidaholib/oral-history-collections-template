# Create this file as _plugins/json_generator.rb

require 'fileutils'
require 'json'
require 'digest'

module Jekyll
  class JsonGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # Create destination directory for transcript JSONs
      FileUtils.mkdir_p(File.join(site.dest, 'assets', 'data', 'transcripts'))
      
      # Get all transcript data from site.data.transcripts
      transcripts = site.data['transcripts']
      return if transcripts.nil?
      
      # Get metadata from site configuration
      metadata_collection = site.data[site.config['metadata']] || []
      
      # Create a comprehensive collection object
      collection_data = {
        'metadata': {
          'title': 'Complete Oral History Collection',
          'description': site.config['description'] || 'Oral history transcripts',
          'date_generated': Time.now.utc.iso8601,
          'transcript_count': transcripts.keys.length
        },
        'transcripts': {}
      }
      
      # For each transcript, create a JSON file and add to comprehensive collection
      transcripts.each do |transcript_name, transcript_data|
        # Find metadata for this transcript
        metadata = metadata_collection.find { |item| item['objectid'] == transcript_name } || {}
        
        # Build JSON structure
        json_data = {
          'title' => metadata['title'] || transcript_name,
          'interviewee' => metadata['interviewee'] || metadata['title'] || transcript_name,
          'interviewer' => metadata['interviewer'],
          'date' => metadata['date'],
          'subjects' => metadata['subject']&.split(';')&.map(&:strip),
          'segments' => []
        }
        
        # Add each segment
        transcript_data.each_with_index do |item, index|
          # Process tags
          tags = item['tags']&.to_s&.split(';')&.compact&.map(&:strip)&.reject { |t| t == "" || t == " " } || []
          
          # Add segment data
          json_data['segments'] << {
            'id' => "#{transcript_name}_#{index}",
            'index' => index,
            'speaker' => item['speaker'],
            'words' => item['words'],
            'tags' => tags,
            'timestamp' => item['timestamp']
          }
        end
        
        # Add transcript metadata
        json_data['metadata'] = {
          'totalSegments' => transcript_data.length,
          'description' => metadata['description'],
          'location' => metadata['location'],
          'source' => metadata['source']
        }
        
        # Add to the comprehensive collection
        collection_data[:transcripts][transcript_name] = json_data
        
        # Write individual JSON file to destination directory
        path = File.join(site.dest, 'assets', 'data', 'transcripts', "#{transcript_name}.json")
        File.open(path, 'w') do |file|
          file.write(JSON.pretty_generate(json_data))
        end
      end
      
      # Create a combined index JSON with basic information about all transcripts
      index_data = transcripts.keys.map do |transcript_name|
        metadata = metadata_collection.find { |item| item['objectid'] == transcript_name } || {}
        {
          'id' => transcript_name,
          'title' => metadata['title'] || transcript_name,
          'interviewee' => metadata['interviewee'] || metadata['title'] || transcript_name,
          'date' => metadata['date'],
          'url' => "/assets/data/transcripts/#{transcript_name}.json"
        }
      end
      
      # Write index JSON file
      index_path = File.join(site.dest, 'assets', 'data', 'transcripts', 'index.json')
      File.open(index_path, 'w') do |file|
        file.write(JSON.pretty_generate(index_data))
      end
      
      # Store collection file in a hidden directory that Jekyll won't watch
      src_path = File.join(site.source, '.data')  # Changed to .data directory
      data_path = File.join(src_path, 'transcript-collection.json')
      
      # Add timestamp check
      should_write = true
      if File.exist?(data_path)
        file_age = Time.now - File.mtime(data_path)
        should_write = file_age > 60 # Only write if more than 1 minute has passed
        
        if should_write
          existing_content = File.read(data_path)
          new_content = JSON.pretty_generate(collection_data)
          existing_hash = Digest::SHA256.hexdigest(existing_content)
          new_hash = Digest::SHA256.hexdigest(new_content)
          should_write = (existing_hash != new_hash)
        end
      end
      
      # Only write if content is different, to avoid regeneration loops
      if should_write
        FileUtils.mkdir_p(src_path)
        File.open(data_path, 'w') do |file|
          file.write(JSON.pretty_generate(collection_data))
        end
        puts "Updated _data/transcript-collection.json with new content"
      else
        puts "No changes to _data/transcript-collection.json, keeping existing file"
      end
    end
  end
end