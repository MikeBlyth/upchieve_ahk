#!/usr/bin/env ruby

require 'sqlite3'
require 'date'
require 'csv'

# --- Helper Functions ---
def canonical_subject(subject_str)
  return nil if subject_str.nil?
  
  s = subject_str.strip.downcase
  
  case s
  when "csp", "ap computer science principles"
    "AP Computer Science Principles"
  when "csa", "ap computer science a"
    "AP Computer Science A"
   when "science", "sciece"
    "Middle School Science"
  when "pre-algebra", "prealbegra"
    "Prealgebra"
  when "algebra 1"
    "Algebra"
  else
    # Default to capitalizing each word
    s.split.map(&:capitalize).join(' ')
  end
end

# --- Configuration ---
LOG_FILE = 'scan.log'
DB_FILE = 'scan_analysis.db'

# --- Main Logic ---

def parse_and_load_data(log_file, db_file)
  # Initialize database
  db = SQLite3::Database.new(db_file)
  db.execute "DROP TABLE IF EXISTS monitoring_periods;"
  db.execute "DROP TABLE IF EXISTS student_requests;"
  db.execute <<-SQL
    CREATE TABLE monitoring_periods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      start_time DATETIME,
      end_time DATETIME
    );
  SQL
  db.execute <<-SQL
    CREATE TABLE student_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp DATETIME,
      student_name TEXT,
      subject TEXT,
      waiting_time_seconds REAL
    );
  SQL

  db.execute "DROP TABLE IF EXISTS app_log_data;"
  db.execute <<-SQL
    CREATE TABLE app_log_data (
      Date TEXT,
      RequestTime TEXT,
      Time TEXT,
      Until TEXT,
      W TEXT,
      Name TEXT,
      Grade INTEGER,
      Fav INTEGER,
      Assignment TEXT,
      Subject TEXT,
      Topic TEXT,
      Math INTEGER,
      Duration TEXT,
      InitialResponse INTEGER,
      SeriousQuestion INTEGER,
      LeftAbruptly INTEGER,
      StoppedResp INTEGER,
      GoodProgress TEXT,
      LastMsg TEXT,
      Comments TEXT,
      Sessions INTEGER
    );
  SQL

  # Regex patterns for parsing log lines
  scan_start_regex = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) - Scan Run Started/
  scan_end_regex = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) - Scan Run Ended/
  student_request_regex = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| (.*?)\s*\((.*?)\)(?:, (.*?))?$/
  
  # State machine for parsing
  in_monitoring_period = false
  current_start_time = nil
  
  # Data structures for burst detection
  topic_requests = Hash.new { |h, k| h[k] = [] }
  cooldown_topics = {}

  file_content = File.read(log_file, encoding: 'UTF-8', undef: :replace, invalid: :replace)
  file_content.each_line do |line|
    line.encode!('UTF-8', invalid: :replace, undef: :replace, replace: '') # Force transcoding
    line = line.strip
    next if line.empty?

    if !in_monitoring_period
      # Look for the start of a monitoring period
      if (match = line.match(scan_start_regex))
        current_start_time = DateTime.parse(match[1])
        in_monitoring_period = true
      end
    else
      # We are in a monitoring period

      # Check for end of monitoring period
      if (match = line.match(scan_end_regex))
        end_time = DateTime.parse(match[1])
        db.execute("INSERT INTO monitoring_periods (start_time, end_time) VALUES (?, ?)", [current_start_time.to_s, end_time.to_s])
        in_monitoring_period = false
        current_start_time = nil
        # Reset burst detection state at the end of a monitoring period
        topic_requests.clear
        cooldown_topics.clear
        next
      end

      # Regexes for different student request formats
      student_request_regex_pipe = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s*\|\s*(.*?)\s*\((.*?)\)$/
      student_request_regex_comma = /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(.*?)\s*\((.*?)\),\s*([\d\.]+)$/
      
      timestamp_str, student_name, subject, waiting_time = nil, nil, nil, nil
      is_student_request = false

      if (match = line.match(student_request_regex_comma))
        timestamp_str, student_name, subject, waiting_time = match[1], match[2], match[3], match[4].to_f
        is_student_request = true
      elsif (match = line.match(student_request_regex_pipe))
        timestamp_str, student_name, subject = match[1], match[2], match[3]
        is_student_request = true
      end

      if is_student_request
        timestamp = DateTime.parse(timestamp_str)
        topic = subject.strip

        # Check and handle cooldown
        if cooldown_topics.key?(topic)
          cooldown_start_time = cooldown_topics[topic]
          if (timestamp.to_time - cooldown_start_time.to_time) < 240 # 4 minutes
            # Still in cooldown, ignore this request
            next
          else
            # Cooldown is over
            cooldown_topics.delete(topic)
          end
        end

        # Prune old requests (older than 90 seconds)
        topic_requests[topic].reject! { |req| (timestamp.to_time - req[:timestamp].to_time) > 90 }

        # Insert the request and get its ID
        db.execute("INSERT INTO student_requests (timestamp, student_name, subject, waiting_time_seconds) VALUES (?, ?, ?, ?)",
                   [timestamp.to_s, student_name.strip, topic, waiting_time])
        last_id = db.last_insert_row_id
        
        # Add current request to the tracking list
        topic_requests[topic] << { timestamp: timestamp, id: last_id }
        
        # Check for burst
        if topic_requests[topic].length >= 4
          # Burst detected, start cooldown and delete the requests
          cooldown_topics[topic] = timestamp
          
          ids_to_delete = topic_requests[topic].map { |req| req[:id] }
          db.execute("DELETE FROM student_requests WHERE id IN (#{ids_to_delete.join(',')})")
          
          topic_requests[topic].clear
        end
      end
    end
  end

  # --- Process upchieve_app.log ---
  app_log_file = 'upchieve_app.log'
  if File.exist?(app_log_file)
    boolean_indices = [7, 11, 13, 14, 15, 16] # Indices for Fav, Math, InitialResponse, etc.

    CSV.foreach(app_log_file, encoding: 'UTF-8', invalid: :replace, undef: :replace) do |row|
      # Take the first 21 fields, padding with nil if the row is shorter.
      log_data = row.first(21)
      if log_data.length < 21
        log_data.fill(nil, log_data.length...21)
      end

      # Convert boolean-like strings to integers by index.
      boolean_indices.each do |index|
        if log_data[index]
          # Check for 'true' or 'false' and convert, otherwise leave as is (for 0, 1, etc.)
          val = log_data[index].to_s.downcase
          if val == 'true'
            log_data[index] = 1
          elsif val == 'false'
            log_data[index] = 0
          end
        end
      end
      
      # Handle Sessions column (index 20): if it's an empty string, make it nil.
      if log_data[20] == ""
        log_data[20] = nil
      end

      # Standardize Subject name (index 9)
      log_data[9] = canonical_subject(log_data[9])

      # Ensure all data is ready for insertion.
      db.execute("INSERT INTO app_log_data VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", log_data)
    end
  end


  puts "Database '#{db_file}' created and populated successfully."

rescue SQLite3::Exception => e
  puts "Database exception: #{e}"
ensure
  db.close if db
end

# --- Execution ---
parse_and_load_data(LOG_FILE, DB_FILE)
