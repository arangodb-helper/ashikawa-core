# -*- encoding : utf-8 -*-
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end

require "ashikawa-core"

port = ENV["ARANGODB_PORT"] || 8529
username = ENV["ARANGODB_USERNAME"] || "root"
password = ENV["ARANGODB_PASSWORD"] || ""

DATABASE = Ashikawa::Core::Database.new do |config|
  config.url = "http://localhost:#{port}"
end

unless ENV["ARANGODB_DISABLE_AUTHENTIFICATION"]
  DATABASE.authenticate_with(username: username, password: password)
end
