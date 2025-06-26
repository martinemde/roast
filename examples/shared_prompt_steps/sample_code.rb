# Sample Ruby code for demonstrating the shared prompt steps
# This code intentionally contains various issues for the review workflow to identify

require 'net/http'
require 'json'

class UserAuthenticationService
  def initialize
    @users = {}
    @sessions = {}
  end

  # Issue: SQL injection vulnerability, no input validation
  def find_user(username)
    query = "SELECT * FROM users WHERE username = '#{username}'"
    # Simulated database query
    puts "Executing query: #{query}"
    @users[username]
  end

  # Issue: Weak password validation, stored in plain text
  def register_user(username, password, email)
    # No input validation
    if password.length > 3  # Weak password requirement
      @users[username] = {
        username: username,
        password: password,  # Plain text password storage!
        email: email,
        created_at: Time.now
      }
      true
    else
      false
    end
  end

  # Issue: No rate limiting, timing attack vulnerability
  def authenticate(username, password)
    user = find_user(username)
    return false unless user
    
    # Character-by-character comparison (timing attack)
    user[:password].chars.each_with_index do |char, i|
      return false if password[i] != char
    end
    
    # Create session
    session_id = rand(10000).to_s  # Weak session ID generation
    @sessions[session_id] = username
    session_id
  end

  # Issue: N+1 query problem, inefficient algorithm
  def get_user_activities(usernames)
    activities = []
    
    # N+1 query issue
    usernames.each do |username|
      user = find_user(username)
      if user
        # Simulated activity fetch (would be another query)
        user_activities = fetch_activities_for_user(username)
        
        # Inefficient nested loop O(n²)
        user_activities.each do |activity|
          activities.each do |existing|
            if activity[:id] == existing[:id]
              # Duplicate check
              next
            end
          end
          activities << activity
        end
      end
    end
    
    activities
  end

  # Issue: Blocking I/O, no connection pooling
  def fetch_external_data(user_id)
    uri = URI("http://api.example.com/users/#{user_id}")  # HTTP instead of HTTPS
    
    # No timeout, no error handling
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)
    
    # Debug mode exposing sensitive data
    puts "Debug: Fetched data for user #{user_id}: #{data}"
    
    data
  rescue => e
    # Generic error handling exposing internal details
    puts "Error fetching data: #{e.message}\n#{e.backtrace}"
    nil
  end

  private

  def fetch_activities_for_user(username)
    # Simulated expensive operation
    sleep(0.1)  # Blocking operation
    
    # Creating large objects in memory
    activities = []
    1000.times do |i|
      activities << {
        id: i,
        username: username,
        action: "action_#{i}",
        timestamp: Time.now,
        data: "x" * 10000  # Large string allocation
      }
    end
    
    activities
  end
end

# Usage example with more issues
service = UserAuthenticationService.new

# No input sanitization from command line
username = ARGV[0]
password = ARGV[1]

# Register and authenticate
service.register_user(username, password, "#{username}@example.com")
session = service.authenticate(username, password)

puts "Session created: #{session}"

# Performance issue - fetching data for many users
users = ["user1", "user2", "user3", "user4", "user5"]
activities = service.get_user_activities(users)

puts "Found #{activities.length} activities"