require 'sinatra'
require 'json'
require 'webrick'
require 'socket'

# Create custom WEBrick server with SO_REUSEADDR properly applied
server_options = {
  :Port => 55000,
  :BindAddress => '0.0.0.0',
  :AccessLog => [],
  :Logger => WEBrick::Log.new($stderr, 0)  # Minimal logging
}

# Custom socket creation to ensure SO_REUSEADDR is set
class CustomTCPServer < TCPServer
  def initialize(host, port)
    super(host, port)
    setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
  end
end

# Override WEBrick's socket creation
module WEBrick::Utils
  class << self
    alias_method :original_create_listeners, :create_listeners

    def create_listeners(address, port)
      socket = CustomTCPServer.new(address, port)
      return [socket]
    rescue => e
      # Fallback to original if custom fails
      original_create_listeners(address, port)
    end
  end
end

set :server, :webrick
set :port, 55000
set :bind, '127.0.0.1'
set :server_settings, server_options

# Graceful Exit
trap("INT") { 
  puts "Closing IPC sockets..."
  exit 
}

# Global storage
$current_students = []
$current_walmart_product = nil
$current_cart_items = nil

# CORS Headers to allow browser extension communication
before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['POST', 'GET', 'DELETE', 'OPTIONS'],
          'Access-Control-Allow-Headers' => 'Content-Type'
end

# Handle preflight OPTIONS request
options '/students' do
  200
end

options '/walmart_product' do
  200
end

options '/sync_cart' do
  200
end

# POST /sync_cart - Receive cart item IDs from Chrome Extension
post '/sync_cart' do
  begin
    payload = JSON.parse(request.body.read)
    if payload['ids']
      $current_cart_items = payload['ids']
      puts "[#{Time.now.strftime('%H:%M:%S')}] Received #{$current_cart_items.length} cart items"
      content_type :json
      { status: 'success', count: $current_cart_items.length }.to_json
    else
      status 400
      { status: 'error', message: 'Missing "ids" key' }.to_json
    end
  rescue JSON::ParserError
    status 400
    { status: 'error', message: 'Invalid JSON' }.to_json
  end
end

# GET /cart_verification - Allow Ruby bot to retrieve captured cart items
get '/cart_verification' do
  content_type :json
  { ids: $current_cart_items }.to_json
end

# DELETE /cart_verification - Clear cart state
delete '/cart_verification' do
  $current_cart_items = nil
  content_type :json
  { status: 'cleared' }.to_json
end

# POST /walmart_product - Receive data from Chrome Extension
post '/walmart_product' do
  begin
    payload = JSON.parse(request.body.read)
    
    $current_walmart_product = payload
    
    if payload['walmart_product']
      puts "[#{Time.now.strftime('%H:%M:%S')}] Received Walmart product: #{payload['description'].to_s[0..30]}..."
    end
    
    content_type :json
    { status: 'success' }.to_json
  rescue JSON::ParserError
    status 400
    { status: 'error', message: 'Invalid JSON' }.to_json
  end
end

# GET /walmart_product - Check current state
get '/walmart_product' do
  content_type :json
  ($current_walmart_product || {}).to_json
end

# DELETE /walmart_product - Clear current state
delete '/walmart_product' do
  $current_walmart_product = nil
  content_type :json
  { status: 'cleared' }.to_json
end

# POST /students - Receive data from Chrome Extension
post '/students' do
  begin
    payload = JSON.parse(request.body.read)
    
    # Expecting {"students": [...]}
    if payload.key?('students')
      $current_students = payload['students']
      
      puts "[#{Time.now.strftime('%H:%M:%S')}] Received #{$current_students.length} students"
      
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
