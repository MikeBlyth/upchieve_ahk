#!/usr/bin/env ruby

require 'csv'

input_file = 'upchieve_app.log'
output_file = 'upchieve_app.csv'

# Expected headers. Total 22 columns.
headers = ["Seq","Date","RequestTime","Time","Until","W","Name","Grade","Fav","Assignment","Subject","Topic","Math","Duration","InitialResponse","SeriousQuestion","LeftAbruptly","StoppedResp","GoodProgress","LastMsg","Comments","Sessions"]

# Indices of key fields
TOPIC_INDEX = 11
MATH_INDEX = 12
COMMENTS_INDEX = 20
SESSIONS_INDEX = 21

begin
  # Read all lines from the source file, attempting to fix encoding issues.
  lines = File.readlines(input_file, encoding: 'UTF-8', invalid: :replace, undef: :replace)
  
  CSV.open(output_file, 'w', write_headers: true, headers: headers) do |csv_out|
    lines.each_with_index do |line, index|
      line.strip!
      next if line.empty? || line.match?(/^=+/) # Skip empty or separator lines

      # Skip header line, it's written by CSV.open
      if index == 0 && line.start_with?('Seq')
        next
      end

      fields = line.split(',')
      
      # Heuristic 1: Fix commas in the 'Topic' field
      # The 'Math' field (0 or 1) should be at index 12. If it's not, we search for it.
      math_field_index = fields.index { |f| f.strip == '0' || f.strip == '1' }

      # We perform the check only if a potential math field is found after the topic index
      # and if there are more fields than expected.
      if fields.length > headers.length && math_field_index && math_field_index > TOPIC_INDEX
        # Merge the parts of the 'Topic' field that were split by commas
        reconstructed_topic = fields[TOPIC_INDEX...math_field_index].join(',')
        
        # Reconstruct the fields array
        fields = fields[0...TOPIC_INDEX] + [reconstructed_topic] + fields[math_field_index..-1]
      end

      # Heuristic 2: Fix commas in the 'Comments' field
      if fields.length > headers.length
        last_field = fields.last.strip
        # Check if the last field is an integer (the Sessions count)
        if last_field.match?(/^\d+$/)
          # If it is, merge everything between Comments and the last field
          reconstructed_comment = fields[COMMENTS_INDEX...-1].join(',')
          fields = fields[0...COMMENTS_INDEX] + [reconstructed_comment] + [fields.last]
        else
          # If it's not, assume everything to the end is part of the comment
          reconstructed_comment = fields[COMMENTS_INDEX..-1].join(',')
          fields = fields[0...COMMENTS_INDEX] + [reconstructed_comment]
        end
      end
      
      # After fixing, pad with empty strings if row is still too short
      while fields.length < headers.length
        fields << ''
      end
      
      # Truncate if it's still too long (shouldn't happen with this logic, but for safety)
      fields = fields[0...headers.length]

      csv_out << fields
    end
  end
  
  puts "Successfully processed '#{input_file}' and created clean CSV '#{output_file}'."

rescue StandardError => e
  STDERR.puts "An error occurred: #{e.message}"
  STDERR.puts e.backtrace
end
