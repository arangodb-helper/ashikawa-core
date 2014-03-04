# -*- encoding : utf-8 -*-
require 'ashikawa-core/exceptions/client_error/resource_not_found/collection_not_found'
require 'ashikawa-core/collection'
require 'ashikawa-core/connection'
require 'ashikawa-core/cursor'
require 'ashikawa-core/configuration'
require 'ashikawa-core/transaction'
require 'forwardable'
require 'equalizer'

module Ashikawa
  module Core
    # An ArangoDB database
    class Database
      COLLECTION_TYPES = {
        document: 2,
        edge: 3
      }

      extend Forwardable

      include Equalizer.new(:host, :port, :scheme)

      # Delegate sending requests to the connection
      def_delegator :@connection, :send_request
      def_delegator :@connection, :host
      def_delegator :@connection, :port
      def_delegator :@connection, :scheme

      # Initializes the connection to the database
      #
      # @api public
      # @example Access a Database by providing the URL
      #   database = Ashikawa::Core::Database.new do |config|
      #     config.url = 'http://localhost:8529'
      #   end
      # @example Access a Database by providing a Connection and authentication
      #   connection = Connection.new('http://localhost:8529')
      #   database = Ashikawa::Core::Database.new do |config|
      #     config.connection = connection
      #     config.username = 'lebowski'
      #     config.password = 'i<3bowling'
      #   end
      # @example Access a certain database from ArangoDB
      #   database = Ashikawa::Core::Database.new do |config|
      #     config.url = 'http://localhost:8529/_db/my_db'
      #     config.connection = connection
      #   end
      # @example Access a Database with a logger and custom HTTP adapter
      #   database = Ashikawa::Core::Database.new do |config|
      #     config.url = 'http://localhost:8529'
      #     config.adapter = my_adapter
      #     config.logger = my_logger
      #   end
      def initialize
        configuration = Ashikawa::Core::Configuration.new
        yield(configuration)
        @connection = configuration.connection
      end

      # Returns a list of all non-system collections defined in the database
      #
      # @return [Array<Collection>]
      # @api public
      # @example Get an Array containing the Collections in the database
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   database['a']
      #   database['b']
      #   database.collections # => [ #<Collection name='a'>, #<Collection name="b">]
      def collections
        all_collections_where { |collection| !collection['name'].start_with?('_') }
      end

      # Returns a list of all system collections defined in the database
      #
      # @return [Array<Collection>]
      # @api public
      # @example Get an Array containing the Collections in the database
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   database.system_collections # => [ #<Collection name='_a'>, #<Collection name="_b">]
      def system_collections
        all_collections_where { |collection| collection['name'].start_with?('_') }
      end

      # Create a Collection based on name
      #
      # @param [String] collection_identifier The desired name of the collection
      # @option options [Boolean] :is_volatile Should the collection be volatile? Default is false
      # @option options [Boolean] :content_type What kind of content should the collection have? Default is :document
      # @return [Collection]
      # @api public
      # @example Create a new, volatile collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   database.create_collection('a', :isVolatile => true) # => #<Collection name="a">
      def create_collection(collection_identifier, options = {})
        response = send_request('collection', post: translate_params(collection_identifier, options))
        Ashikawa::Core::Collection.new(self, response)
      end

      # Get or create a Collection based on name or ID
      #
      # @param [String, Fixnum] collection_identifier The name or ID of the collection
      # @return [Collection]
      # @api public
      # @example Get a Collection from the database by name
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   database['a'] # => #<Collection name="a">
      # @example Get a Collection from the database by ID
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   database['7254820'] # => #<Collection id=7254820>
      def collection(collection_identifier)
        begin
          response = send_request("collection/#{collection_identifier}")
        rescue CollectionNotFoundException
          response = send_request('collection', post: { name: collection_identifier })
        end

        Ashikawa::Core::Collection.new(self, response)
      end

      alias_method :[], :collection

      # Return a Query initialized with this database
      #
      # @return [Query]
      # @api public
      # @example Send an AQL query to the database
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   database.query.execute 'FOR u IN users LIMIT 2' # => #<Cursor id=33>
      def query
        Query.new(self)
      end

      # Create a new Transaction for this database
      #
      # @param [String] action The JS action you want to execute
      # @options collections [Array<String>] :read The collections you want to read from
      # @options collections [Array<String>] :write The collections you want to write to
      # @return [Object] The result of the transaction
      # @api public
      # @example Create a new Transaction
      #   transaction = database.create_transaction('function () { return 5; }", :read => ["collection_1'])
      #   transaction.execute #=> 5
      def create_transaction(action, collections)
        Ashikawa::Core::Transaction.new(self, action, collections)
      end

      private

      # Parse a raw collection
      #
      # @param [Array] raw_collections
      # @return [Array]
      # @api private
      def parse_raw_collections(raw_collections)
        raw_collections.map { |collection|
          Ashikawa::Core::Collection.new(self, collection)
        }
      end

      # Translate the key options into the required format
      #
      # @param [Hash] key_options
      # @return [Hash]
      # @api private
      def translate_key_options(key_options)
        {
          type: key_options[:type].to_s,
          offset: key_options[:offset],
          increment: key_options[:increment],
          allowUserKeys: key_options[:allow_user_keys]
        }
      end

      # Translate the params into the required format
      #
      # @param [String] collection_identifier
      # @param [Hash] opts
      # @return [Hash]
      # @api private
      def translate_params(collection_identifier, opts)
        params = { name: collection_identifier }
        params[:isVolatile] = true if opts[:is_volatile]
        params[:type] = COLLECTION_TYPES[opts[:content_type]] if opts.key?(:content_type)
        params[:keyOptions] = translate_key_options(opts[:key_options]) if opts.key?(:key_options)
        params
      end

      # Get all collections that fulfill a certain criteria
      #
      # @yield [raw_collection] Yields the raw collections so you can decide which to keep
      # @yieldparam [raw_collection] A raw collection
      # @yieldreturn [Boolean] Should the collection be kept
      # @return [Array<Collection>]
      # @api private
      def all_collections_where(&block)
        raw_collections = send_request('collection')['collections']
        raw_collections.keep_if(&block)
        parse_raw_collections(raw_collections)
      end
    end
  end
end
