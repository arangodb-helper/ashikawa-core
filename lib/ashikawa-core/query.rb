require 'ashikawa-core/cursor'
require 'ashikawa-core/document'
require 'ashikawa-core/exceptions/no_collection_provided'
require 'ashikawa-core/exceptions/client_error/bad_syntax'
require 'forwardable'
require 'backports'

module Ashikawa
  module Core
    # Formulate a Query on a collection or on a database
    class Query
      extend Forwardable

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
      def all(options={})
        simple_query_request("simple/all",
          options,
          [:limit, :skip])
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
      #   query.by_example({ "color" => "red" }, :options => { :limit => 1 }) #=> #<Cursor id=2444>
      def by_example(example={}, options={})
        simple_query_request("simple/by-example",
          { :example => example }.merge(options),
          [:limit, :skip, :example])
      end

      # Looks for one document in a collection which matches the given criteria
      #
      # @param [Hash] example a Hash with data matching the document you are looking for.
      # @return [Document]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Find one document in a collection that is red
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.first_example({ "color" => "red"}) # => #<Document id=2444 color="red">
      def first_example(example = {})
        simple_query_request("simple/first-example",
          { :example => example },
          [:example])
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
      def near(options={})
        simple_query_request("simple/near",
          options,
          [:latitude, :longitude, :distance, :skip, :limit, :geo])
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
      def within(options={})
        simple_query_request("simple/within",
          options,
          [:latitude, :longitude, :radius, :distance, :skip, :limit, :geo])
      end

      # Looks for documents in a collection with an attribute between two values
      #
      # @option options [Integer] :attribute The attribute path to check.
      # @option options [Integer] :left The lower bound
      # @option options [Integer] :right The upper bound
      # @option options [Integer] :closed If true, use intervall including left and right, otherwise exclude right, but include left.
      # @option options [Integer] :skip The documents to skip in the query (optional).
      # @option options [Integer] :limit The maximal amount of documents to return (optional).
      # @return [Cursor]
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api public
      # @example Find all documents within a radius of 100 to Infinite Loop
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.within(:latitude => 37.331693, :longitude => -122.030468, :radius => 100)
      def in_range(options={})
        simple_query_request("simple/range",
          options,
          [:attribute, :left, :right, :closed, :limit, :skip])
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
      #   query.execute("FOR u IN users LIMIT 2") # => #<Cursor id=33>
      def execute(query, options = {})
        post_request("cursor",
          options.merge({ :query => query }),
          [:query, :count, :batch_size])
      end

      # Test if an AQL query is valid
      #
      # @param [String] query
      # @return [Boolean]
      # @api public
      # @example Validate an AQL query
      #   query = Ashikawa::Core::Query.new(collection)
      #   query.valid?("FOR u IN users LIMIT 2") # => true
      def valid?(query)
        !!post_request("query", { :query => query })
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
      def allowed_options(options, allowed_keys)
        options.keep_if { |key, _| allowed_keys.include?(key) }
      end

      # Transforms the keys into the required format
      #
      # @param [Hash] request_data
      # @return [Hash] Cleaned request data
      # @api private
      def prepare_request_data(request_data)
        Hash[request_data.map { |key, value|
          [key.to_s.gsub(/_(.)/) { $1.upcase }, value]
        }].reject { |_, value| value.nil? }
      end

      # Send a simple query to the server
      #
      # @param [String] path The path for the request
      # @param [Hash] request_data The data send to the database
      # @param [Array<Symbol>] allowed_keys The keys allowed for this request
      # @return [String] Server response
      # @raise [NoCollectionProvidedException] If you provided a database, no collection
      # @api private
      def simple_query_request(path, request_data, allowed_keys)
        request_data = request_data.merge({ :collection => collection.name })
        put_request(path,
          request_data,
          allowed_keys << :collection)
      end

      # Perform a wrapped request
      #
      # @param [String] path The path for the request
      # @param [Symbol] request_method The request method to perform
      # @param [Hash] request_data The data send to the database
      # @param [Array] allowed_keys Keys allowed in request_data, if nil: All keys are allowed
      # @return [Cursor]
      # @api private
      def wrapped_request(path, request_method, request_data, allowed_keys)
        request_data = allowed_options(request_data, allowed_keys) unless allowed_keys.nil?
        request_data = prepare_request_data(request_data)
        server_response = send_request(path, { request_method => request_data })
        Cursor.new(database, server_response)
      end

      # Perform a wrapped put request
      #
      # @param [String] path The path for the request
      # @param [Hash] request_data The data send to the database
      # @param [Array] allowed_keys Keys allowed in request_data, if nil: All keys are allowed
      # @return [Cursor]
      # @api private
      def put_request(path, request_data, allowed_keys = nil)
        wrapped_request(path, :put, request_data, allowed_keys)
      end

      # Perform a wrapped post request
      #
      # @param [String] path The path for the request
      # @param [Hash] request_data The data send to the database
      # @param [Array] allowed_keys Keys allowed in request_data, if nil: All keys are allowed
      # @return [Cursor]
      # @api private
      def post_request(path, request_data, allowed_keys = nil)
        wrapped_request(path, :post, request_data, allowed_keys)
      end
    end
  end
end
