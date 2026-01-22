require 'sinatra'
require 'json'

# Configure Sinatra
set :port, 4567
set :bind, '127.0.0.1'

# Global storage
$current_students = []

# CORS Headers to allow browser extension communication
before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['POST', 'GET', 'OPTIONS'],
          'Access-Control-Allow-Headers' => 'Content-Type'
end

# Handle preflight OPTIONS request
options '/students' do
  200
end

# POST /students - Receive data from Chrome Extension
post '/students' do
  begin
    payload = JSON.parse(request.body.read)
    
    # Expecting {"students": [...]}
    if payload.key?('students')
      $current_students = payload['students']
      
      puts "[#{Time.now.strftime('%H:%M:%S')}] Received #{$current_students.length} students"
      
      # Write to file for potential AHK/other consumption
      File.write('current_students.json', JSON.pretty_generate($current_students))
      
      content_type :json
      { status: 'success', count: $current_students.length }.to_json
    else
      status 400
      { status: 'error', message: 'Missing "students" key' }.to_json
    end
  rescue JSON::ParserError
    status 400
    { status: 'error', message: 'Invalid JSON' }.to_json
  end
end

# GET /students - Check current state
get '/students' do
  content_type :json
  { students: $current_students }.to_json
end

# GET /ahk_data - Optimized string format for AutoHotkey
get '/ahk_data' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  content_type :text
  
  ahk_string = "*upchieve"
  $current_students.each do |student|
    minutes = student['minutes'] || 0
    # Clean pipe characters from data to prevent parsing errors
    name = student['name'].to_s.gsub('|', '')
    topic = student['topic'].to_s.gsub('|', '')
    
    ahk_string += "|#{name}|#{topic}|#{minutes}"
  end
  
  ahk_string
end
