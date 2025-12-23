#!/usr/bin/env ruby

require 'sqlite3'
require 'date'

# --- Configuration ---
DB_FILE = 'scan_analysis.db'

# --- Helper Methods ---
def median(array)
  return nil if array.empty?
  sorted = array.sort
  len = sorted.length
  mid = len / 2
  if len.even?
    (sorted[mid - 1] + sorted[mid]) / 2.0
  else
    sorted[mid]
  end
end


# --- Main Logic ---

def analyze_data(db_file)
  db = SQLite3::Database.new(db_file)
  db.results_as_hash = true

  puts "--- Scan Log Analysis ---"

  # 1. Requests per hour of the day
  puts "\n--- Requests per Hour of the Day ---"
  requests_per_hour = db.execute("SELECT strftime('%H', timestamp) as hour, COUNT(*) as count FROM student_requests GROUP BY hour ORDER BY hour")
  requests_per_hour.each do |row|
    puts "Hour #{row['hour']}: #{row['count']} requests"
  end

  # 2. Requests per day of the week
  puts "\n--- Requests per Day of the Week ---"
  # Note: %w is 0 for Sunday, 1 for Monday, etc.
  day_map = {0 => 'Sunday', 1 => 'Monday', 2 => 'Tuesday', 3 => 'Wednesday', 4 => 'Thursday', 5 => 'Friday', 6 => 'Saturday'}
  requests_per_day = db.execute("SELECT strftime('%w', timestamp) as day_of_week, COUNT(*) as count FROM student_requests GROUP BY day_of_week ORDER BY day_of_week")
  requests_per_day.each do |row|
    day_name = day_map[row['day_of_week'].to_i]
    puts "#{day_name}: #{row['count']} requests"
  end

  # 2a. Normalized Requests per Day (per 12 hours of scan time)
  puts "\n--- Normalized Requests per Day (per 12 hours of scan time) ---"
  monitoring_by_day = Hash.new(0.0)
  db.execute("SELECT start_time, end_time FROM monitoring_periods") do |period|
    start_time = DateTime.parse(period['start_time'])
    end_time = DateTime.parse(period['end_time'])

    current_time = start_time
    while current_time < end_time
      day_start = DateTime.new(current_time.year, current_time.month, current_time.day)
      day_end = day_start + 1

      overlap_start = [current_time, day_start].max
      overlap_end = [end_time, day_end].min
      
      duration_in_seconds = (overlap_end - overlap_start) * 24 * 60 * 60
      
      monitoring_by_day[current_time.wday] += duration_in_seconds
      
      current_time = day_end
    end
  end

  requests_per_day.each do |row|
    day_of_week = row['day_of_week'].to_i
    requests = row['count']
    day_name = day_map[day_of_week]
    
    total_hours_monitored = monitoring_by_day[day_of_week] / 3600.0
    
    if total_hours_monitored > 0
      normalized_requests = (requests * 12) / total_hours_monitored
      puts "#{day_name}: #{normalized_requests.round(2)} normalized requests"
    else
      puts "#{day_name}: No monitoring data"
    end
  end

  # 3. Average waiting time per subject
  puts "\n--- Average Waiting Time per Subject (in seconds) ---"
  avg_wait_per_subject = db.execute("SELECT subject, AVG(waiting_time_seconds) as avg_wait FROM student_requests WHERE waiting_time_seconds IS NOT NULL GROUP BY subject ORDER BY avg_wait DESC")
  avg_wait_per_subject.each do |row|
    puts "#{row['subject']}: #{row['avg_wait'].round(2)} seconds"
  end

  # 3a. Median waiting time per subject
  puts "\n--- Median Waiting Time per Subject (in seconds) ---"
  wait_times_by_subject = Hash.new { |h, k| h[k] = [] }
  db.execute("SELECT subject, waiting_time_seconds FROM student_requests WHERE waiting_time_seconds IS NOT NULL") do |row|
    wait_times_by_subject[row['subject']] << row['waiting_time_seconds']
  end

  median_wait_by_subject = wait_times_by_subject.map do |subject, times|
    [subject, median(times)]
  end.sort_by { |_, median_time| -median_time }

  median_wait_by_subject.each do |subject, median_time|
    puts "#{subject}: #{median_time.round(2)} seconds"
  end

  # 4. Hourly Request Density
  puts "\n--- Hourly Request Density (Requests per Monitored Hour) ---"
  monitoring_by_hour = Hash.new(0.0)
  db.execute("SELECT start_time, end_time FROM monitoring_periods") do |period|
    start_time = DateTime.parse(period['start_time'])
    end_time = DateTime.parse(period['end_time'])

    current_time = start_time
    while current_time < end_time
      hour_start = DateTime.new(current_time.year, current_time.month, current_time.day, current_time.hour)
      hour_end = hour_start + (1/24.0)

      overlap_start = [current_time, hour_start].max
      overlap_end = [end_time, hour_end].min
      
      duration_in_seconds = (overlap_end - overlap_start) * 24 * 60 * 60
      
      monitoring_by_hour[current_time.hour] += duration_in_seconds
      
      current_time = hour_end
    end
  end

  requests_per_hour.each do |row|
    hour = row['hour'].to_i
    requests = row['count']
    total_hours_monitored = monitoring_by_hour[hour] / 3600.0
    
    if total_hours_monitored > 0
      density = requests / total_hours_monitored
      puts "Hour #{hour}: #{density.round(2)} requests per monitored hour"
    else
      puts "Hour #{hour}: No monitoring data"
    end
  end

  # 5. Median waiting time by hour
  puts "\n--- Median Waiting Time by Hour (in seconds) ---"
  wait_times_by_hour = Hash.new { |h, k| h[k] = [] }
  db.execute("SELECT strftime('%H', timestamp) as hour, waiting_time_seconds FROM student_requests WHERE waiting_time_seconds IS NOT NULL") do |row|
    wait_times_by_hour[row['hour']] << row['waiting_time_seconds']
  end

  median_wait_by_hour = wait_times_by_hour.map do |hour, times|
    [hour, median(times)]
  end.sort_by { |hour, _| hour }

  median_wait_by_hour.each do |hour, median_time|
    puts "Hour #{hour}: #{median_time.round(2)} seconds"
  end

rescue SQLite3::Exception => e
  puts "Database error: #{e}"
ensure
  db.close if db
end

# --- Execution ---
analyze_data(DB_FILE)
