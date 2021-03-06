# -*- encoding : utf-8 -*-
require 'forwardable'
require 'faraday'
require 'equalizer'
require 'ashikawa-core/error_response'
require 'ashikawa-core/x_arango_version'
require 'ashikawa-core/faraday_factory'

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
      #   connection = Connection.new('http://localhost:8529', '_system')
      #   connection.host # => 'localhost'
      def_delegator :@connection, :host

      # The scheme of the connection
      #
      # @!method scheme
      # @return [String]
      # @api public
      # @example Get the scheme of the connection
      #   connection = Connection.new('http://localhost:8529', '_system')
      #   connection.scheme # => 'http'
      def_delegator :@connection, :scheme

      # The port of the connection
      #
      # @!method port
      # @return [Fixnum]
      # @api public
      # @example Get the port of the connection
      #   connection = Connection.new('http://localhost:8529', '_system')
      #   connection.port # => 8529
      def_delegator :@connection, :port

      # The Faraday connection object
      #
      # @return [Faraday]
      # @api public
      # @example Set additional response middleware
      #   connection = Connection.new('http://localhost:8529', '_system')
      #   connection.connection.response :caching
      attr_reader :connection

      # The name of the database you want to talk with
      # @return [String]
      # @api public
      # @example Get the name of the database
      #   connection = Connection.new('http://localhost:8529', 'ashikawa')
      #   connection.database_name # => 'ashikawa'
      attr_reader :database_name

      # Initialize a Connection with a given API String
      #
      # @param [String] api_string scheme, hostname and port as a String
      # @param [String] database_name The name of the database you want to communicate with
      # @option options [Object] adapter The Faraday adapter you want to use. Defaults to Default Adapter
      # @option options [Object] debug_headers Should HTTP header be logged or not
      # @option options [Object] logger The logger you want to use. Defaults to no logger.
      # @option options [Array] additional_request_middlewares Additional request middlewares
      # @option options [Array] additional_response_middlewares Additional response middlewares
      # @option options [Array] additional_middlewares Additional middlewares
      # @api public
      # @example Create a new Connection with no additional options
      #  connection = Connection.new('http://localhost:8529', '_system')
      # @example Create a new Connection with additional options
      #  connection = Connection.new('http://localhost:8529', '_system', {
      #    adapter: :typhoeus,
      #    logger: Yell.new(STDOUT),
      #    additional_request_middleware: [:my_request_middleware]
      #    additional_response_middleware: [:my_response_middleware]
      #  })
      def initialize(api_string, database_name, options = {})
        @api_string = api_string
        @database_name = database_name
        @connection = FaradayFactory.create_connection("#{api_string}/_db/#{database_name}/_api", options)
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
      rescue Faraday::Error::ParsingError
        raise Ashikawa::Core::JsonError
      end

      # Sends a request to a given path without the database suffix returning the parsed result
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
      def send_request_without_database_suffix(path, params = {})
        send_request("#{@api_string}/_api/#{path}", params)
      end

      # Checks if authentication for this Connection is active or not
      #
      # @return [Boolean]
      # @api public
      # @example Is authentication activated for this connection?
      #   connection = Connection.new('http://localhost:8529', '_system')
      #   connection.authentication? #=> false
      #   connection.authenticate_with(:username => 'james', :password => 'bond')
      #   connection.authentication? #=> true
      def authentication?
        !!@authentication
      end

      # Authenticate with given username and password
      #
      # @param [String] username
      # @param [String] password
      # @return [String] Basic Auth info (Base 64 of username:password)
      # @api private
      def authenticate_with(username, password)
        @authentication = @connection.basic_auth(username, password)
      end

      private

      # Return the HTTP Verb for the given parameters
      #
      # @param [Hash] params The params given to the method
      # @return [Symbol] The HTTP verb used
      # @api private
      def http_verb(params)
        [:post, :put, :delete].detect { |method_name|
          params.key?(method_name)
        } || :get
      end
    end
  end
end
