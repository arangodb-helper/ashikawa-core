$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

# Do not run SimpleCov in Guard
unless defined?(Guard)
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name     'spec:unit'
    add_filter       'config'
    add_filter       'spec'
    minimum_coverage 99
  end
end

# Helper to simulate Server Responses. Parses the fixtures in the spec folder
require "json"
def server_response(path)
  JSON.parse(File.readlines("spec/fixtures/#{path}.json").join)
end

ARANGO_HOST = "http://localhost:8529"
