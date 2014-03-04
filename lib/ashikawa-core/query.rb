# -*- encoding : utf-8 -*-
require 'ashikawa-core/cursor'
require 'ashikawa-core/document'
require 'ashikawa-core/exceptions/no_collection_provided'
require 'ashikawa-core/exceptions/client_error/bad_syntax'
require 'forwardable'

module Ashikawa
  module Core
    # Formulate a Query on a collection or on a database
    class Query
      extend Forwardable

      ALLOWED_KEYS_FOR_PATH = {
        'simple/all'           => [:limit, :skip, :collection],
        'simple/by-example'    => [:limit, :skip, :example, :collection],
        'simple/near'          => [:latitude, :longitude, :distance, :skip, :limit, :geo, :collection],
        'simple/within'        => [:latitude, :longitude, :radius, :distance, :skip, :limit, :geo, :collection],
        'simple/range'         => [:attribute, :left, :right, :closed, :limit, :skip, :collection],
        'cursor'               => [:query, :count, :batch_size, :collection],
        'query'                => [:query],
        'simple/first-example' => [:example, :collection]
      }

      # Delegate sending requests to the connection
      def_delegator :@connection, :send_request

      # Initializes a Query
      #
      # @param [Collection, Database] connection
      # @return [Query]
      # @api public
      # @example Create a new query object
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   query = Ashikawa::Core::Query.new(collection)
      def initialize(connection)
        @connection = connection
      end

      # Retrieves all documents for a collection
      #
      # @note It is advised to NOT use this method due to possible HUGE data amounts requested
      # @option options [Integer] :limit limit the maximum number of queried and returned elements.
      # @option options [Integer] :skip skip the first <n> documents of the query.
      # @return [Cursor]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Get an array with all documents
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.all # => #<Cursor id=33>
      def all(options = {})
        simple_query_request('simple/all', options)
      end

      # Looks for documents in a collection which match the given criteria
      #
      # @option example [Hash] a Hash with data matching the documents you are looking for.
      # @option options [Hash] a Hash with additional settings for the query.
      # @option options [Integer] :limit limit the maximum number of queried and returned elements.
      # @option options [Integer] :skip skip the first <n> documents of the query.
      # @return [Cursor]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Find all documents in a collection that are red
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.by_example({ 'color' => 'red' }, { :limit => 1 }) #=> #<Cursor id=2444>
      def by_example(example = {}, options = {})
        simple_query_request('simple/by-example', { example: example }.merge(options))
      end

      # Looks for one document in a collection which matches the given criteria
      #
      # @param [Hash] example a Hash with data matching the document you are looking for.
      # @return [Document]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Find one document in a collection that is red
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.first_example({ 'color' => 'red'}) # => #<Document id=2444 color="red">
      def first_example(example = {})
        request = prepare_request('simple/first-example', { example: example, collection: collection.name })
        response = send_request('simple/first-example', { put: request })
        Document.new(database, response['document'])
      end

      # Looks for documents in a collection based on location
      #
      # @option options [Integer] :latitude Latitude location for your search.
      # @option options [Integer] :longitude Longitude location for your search.
      # @option options [Integer] :skip The documents to skip in the query.
      # @option options [Integer] :distance If given, the attribute key used to store the distance.
      # @option options [Integer] :limit The maximal amount of documents to return (default: 100).
      # @option options [Integer] :geo If given, the identifier of the geo-index to use.
      # @return [Cursor]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Find all documents at Infinite Loop
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.near(:latitude => 37.331693, :longitude => -122.030468)
      def near(options = {})
        simple_query_request('simple/near', options)
      end

      # Looks for documents in a collection within a radius
      #
      # @option options [Integer] :latitude Latitude location for your search.
      # @option options [Integer] :longitude Longitude location for your search.
      # @option options [Integer] :radius Radius around the given location you want to search in.
      # @option options [Integer] :skip The documents to skip in the query.
      # @option options [Integer] :distance If given, the attribute key used to store the distance.
      # @option options [Integer] :limit The maximal amount of documents to return (default: 100).
      # @option options [Integer] :geo If given, the identifier of the geo-index to use.
      # @return [Cursor]
      # @api public
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @example Find all documents within a radius of 100 to Infinite Loop
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.within(:latitude => 37.331693, :longitude => -122.030468, :radius => 100)
      def within(options = {})
        simple_query_request('simple/within', options)
      end

      # Looks for documents in a collection with an attribute between two values
      #
      # @option options [Integer] :attribute The attribute path to check.
      # @option options [Integer] :left The lower bound
      # @option options [Integer] :right The upper bound
      # @option options [Integer] :closed If true, the interval includes right
      # @option options [Integer] :skip The documents to skip in the query (optional).
      # @option options [Integer] :limit The maximal amount of documents to return (optional).
      # @return [Cursor]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Find all documents within a radius of 100 to Infinite Loop
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.within(:latitude => 37.331693, :longitude => -122.030468, :radius => 100)
      def in_range(options = {})
        simple_query_request('simple/range', options)
      end

      # Send an AQL query to the database
      #
      # @param [String] query
      # @option options [Integer] :count Should the number of results be counted?
      # @option options [Integer] :batch_size Set the number of results returned at once
      # @return [Cursor]
      # @api public
      # @example Send an AQL query to the database
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.execute('FOR u IN users LIMIT 2') # => #<Cursor id=33>
      def execute(query, options = {})
        wrapped_request('cursor', :post, options.merge({ query: query }))
      end

      # Test if an AQL query is valid
      #
      # @param [String] query
      # @return [Boolean]
      # @api public
      # @example Validate an AQL query
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.valid?('FOR u IN users LIMIT 2') # => true
      def valid?(query)
        !!wrapped_request('query', :post, { query: query })
      rescue Ashikawa::Core::BadSyntax
        false
      end

      private

      # The database object
      #
      # @return [Database]
      # @api private
      def database
        @connection.respond_to?(:database) ? @connection.database : @connection
      end

      # The collection object
      #
      # @return [collection]
      # @api private
      def collection
        raise NoCollectionProvidedException unless @connection.respond_to?(:database)
        @connection
      end

      # Removes the keys that are not allowed from an object
      #
      # @param [Hash] options
      # @param [Array<Symbol>] allowed_keys
      # @return [Hash] The filtered Hash
      # @api private
      def prepare_request(path, options)
        allowed_keys = ALLOWED_KEYS_FOR_PATH.fetch(path)
        options.keep_if { |key, _| allowed_keys.include?(key) }
        options.reduce({}) { |result, (key, value)|
          result[snake_to_camel_case(key.to_s)] = value
          result
        }
      end

      # Translates Snake Case to Camel Case
      #
      # @param [String] str
      # @return [String] The translated String
      # @api private
      def snake_to_camel_case(str)
        str.gsub(/_(.)/) { |match| match[1].upcase }
      end

      # Send a simple query to the server
      #
      # @param [String] path The path for the request
      # @param [Hash] request The data send to the database
      # @param [Array<Symbol>] allowed_keys The keys allowed for this request
      # @return [String] Server response
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api private
      def simple_query_request(path, request)
        wrapped_request(path, :put, request.merge({ collection: collection.name }))
      end

      # Perform a wrapped request
      #
      # @param [String] path The path for the request
      # @param [Symbol] request_method The request method to perform
      # @param [Hash] request The data send to the database
      # @param [Array] allowed_keys Keys allowed in request, if nil: All keys are allowed
      # @return [Cursor]
      # @api private
      def wrapped_request(path, request_method, request)
        request = prepare_request(path, request)
        response = send_request(path, { request_method => request })
        Cursor.new(database, response)
      end
    end
  end
end
