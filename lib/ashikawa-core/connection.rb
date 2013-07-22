require "forwardable"
require "faraday"
require "null_logger"
require "uri"
require "equalizer"
require "ashikawa-core/request_preprocessor"
require "ashikawa-core/response_preprocessor"

module Ashikawa
  module Core
    # A Connection via HTTP to a certain host
    class Connection
      extend Forwardable

      include Equalizer.new(:host, :scheme, :port)

      # The host part of the connection
      #
      # @!method host
      # @return [String]
      # @api public
      # @example Get the host part of the connection
      #   connection = Connection.new("http://localhost:8529")
      #   connection.host # => "localhost"
      def_delegator :@connection, :host

      # The scheme of the connection
      #
      # @!method scheme
      # @return [String]
      # @api public
      # @example Get the scheme of the connection
      #   connection = Connection.new("http://localhost:8529")
      #   connection.scheme # => "http"
      def_delegator :@connection, :scheme

      # The port of the connection
      #
      # @!method port
      # @return [Fixnum]
      # @api public
      # @example Get the port of the connection
      #   connection = Connection.new("http://localhost:8529")
      #   connection.port # => 8529
      def_delegator :@connection, :port

      # Initialize a Connection with a given API String
      #
      # @param [String] api_string scheme, hostname and port as a String
      # @option opts [Object] adapter The Faraday adapter you want to use. Defaults to Default Adapter
      # @option opts [Object] logger The logger you want to use. Defaults to Null Logger.
      # @api public
      # @example Create a new Connection
      #  connection = Connection.new("http://localhost:8529")
      def initialize(api_string, opts = {})
        logger  = opts[:logger]  || NullLogger.instance
        adapter = opts[:adapter] || Faraday.default_adapter
        @connection = Faraday.new("#{api_string}/_api") do |connection|
          connection.request  :ashikawa_request,  logger
          connection.response :ashikawa_response, logger
          connection.adapter(*adapter)
        end
      end

      # Sends a request to a given path returning the parsed result
      # @note prepends the api_string automatically
      #
      # @param [string] path the path you wish to send a request to.
      # @option params [hash] :post post data in case you want to send a post request.
      # @return [hash] parsed json response from the server
      # @api public
      # @example get request
      #   connection.send_request('/collection/new_collection')
      # @example post request
      #   connection.send_request('/collection/new_collection', :post => { :name => 'new_collection' })
      def send_request(path, params = {})
        method = http_verb(params)
        result = @connection.public_send(method, path, params[method])
        result.body
      end

      # Checks if authentication for this Connection is active or not
      #
      # @return [Boolean]
      # @api public
      # @example Is authentication activated for this connection?
      #   connection = Connection.new("http://localhost:8529")
      #   connection.authentication? #=> false
      #   connection.authenticate_with(:username => 'james', :password => 'bond')
      #   connection.authentication? #=> true
      def authentication?
        !!@authentication
      end

      # Authenticate with given username and password
      #
      # @option [String] username
      # @option [String] password
      # @return [self]
      # @raise [ArgumentError] if username or password are missing
      # @api public
      # @example Authenticate with the database for all future requests
      #   connection = Connection.new("http://localhost:8529")
      #   connection.authenticate_with(:username => 'james', :password => 'bond')
      def authenticate_with(options = {})
        raise ArgumentError, 'missing username or password' unless options.key? :username and options.key? :password
        @authentication = @connection.basic_auth(options[:username], options[:password])
        self
      end

      private

      # Return the HTTP Verb for the given parameters
      #
      # @param [Hash] params The params given to the method
      # @return [Symbol] The HTTP verb used
      # @api private
      def http_verb(params)
        [:post, :put, :delete].detect { |method_name|
          params.has_key?(method_name)
        } || :get
      end
    end
  end
end
