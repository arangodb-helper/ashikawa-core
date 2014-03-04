# -*- encoding : utf-8 -*-
require 'ashikawa-core/document'
require 'ashikawa-core/edge'
require 'ashikawa-core/index'
require 'ashikawa-core/cursor'
require 'ashikawa-core/query'
require 'ashikawa-core/status'
require 'ashikawa-core/figure'
require 'ashikawa-core/key_options'
require 'forwardable'
require 'equalizer'

module Ashikawa
  module Core
    # A certain Collection within the Database
    class Collection
      extend Forwardable

      include Equalizer.new(:id, :name, :content_type, :database)

      CONTENT_TYPES = {
        2 => :document,
        3 => :edge
      }

      CONTENT_CLASS = {
        document: Document,
        edge: Edge
      }

      # The name of the collection, must be unique
      #
      # @return [String]
      # @api public
      # @example Change the name of a collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.name # => 'example_1'
      #   collection.name = 'example_2'
      #   collection.name # => 'example_2'
      attr_reader :name

      # The ID of the collection. Is set by the database and unique
      #
      # @return [Fixnum]
      # @api public
      # @example Get the id of the collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.id #=> 4588
      attr_reader :id

      # A wrapper around the status of the collection
      #
      # @return [Status]
      # @api public
      # @example
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.status.loaded? #=> true
      #   collection.status.new_born? #=> false
      attr_reader :status

      # The database the collection belongs to
      #
      # @return [Database]
      # @api public
      # @example
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.database #=> #<Database: ...>
      attr_reader :database

      # The kind of content in the collection: Documents or Edges
      #
      # @return [:document, :edge]
      # @api public
      # @example
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.content_type #=> :document
      attr_reader :content_type

      # Sending requests is delegated to the database
      def_delegator :@database, :send_request

      # Create a new Collection object with a name and an optional ID
      #
      # @param [Database] database The database the connection belongs to
      # @param [Hash] raw_collection The raw collection returned from the server
      # @api public
      # @example Create a Collection object from scratch
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      def initialize(database, raw_collection)
        @database = database
        parse_raw_collection(raw_collection)
        @content_class = CONTENT_CLASS[@content_type]
      end

      # Change the name of the collection
      #
      # @param [String] new_name New Name
      # @return [String] New Name
      # @api public
      # @example Change the name of a collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.name # => 'example_1'
      #   collection.name = 'example_2'
      #   collection.name # => 'example_2'
      def name=(new_name)
        send_information_to_server(:rename, :name, new_name)
        @name = new_name
      end

      # Does the document wait until the data has been synchronised to disk?
      #
      # @return [Boolean]
      # @api public
      # @example Does the collection wait for file synchronization?
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.wait_for_sync? #=> false
      def wait_for_sync?
        get_information_from_server(:properties, :waitForSync)
      end

      # Change if the document will wait until the data has been synchronised to disk
      #
      # @return [String] Response from the server
      # @api public
      # @example Tell the collection to wait for file synchronization
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.wait_for_sync = true
      def wait_for_sync=(new_value)
        send_information_to_server(:properties, :waitForSync, new_value)
      end

      # Get information about the type of keys of this collection
      #
      # @return [KeyOptions]
      # @api public
      # @example Check if this collection has autoincrementing keys
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.key_options.type # => 'autoincrement'
      def key_options
        KeyOptions.new(get_information_from_server(:properties, :keyOptions))
      end

      # Returns the number of documents in the collection
      #
      # @return [Fixnum] Number of documents
      # @api public
      # @example How many documents are in the collection?
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.length # => 0
      def length
        get_information_from_server(:count, :count)
      end

      # Return a Figure initialized with current data for the collection
      #
      # @return [Figure]
      # @api public
      # @example Get the datafile count for a collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.figure.datafiles_count #=> 0
      def figure
        raw_figure = get_information_from_server(:figures, :figures)
        Figure.new(raw_figure)
      end

      # Deletes the collection
      #
      # @return [String] Response from the server
      # @api public
      # @example Delete a collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.delete
      def delete
        send_request_for_this_collection('', delete: {})
      end

      # Load the collection into memory
      #
      # @return [String] Response from the server
      # @api public
      # @example Load a collection into memory
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.load
      def load
        send_command_to_server(:load)
      end

      # Load the collection into memory
      #
      # @return [String] Response from the server
      # @api public
      # @example Unload a collection into memory
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.unload
      def unload
        send_command_to_server(:unload)
      end

      # Delete all documents from the collection
      #
      # @return [String] Response from the server
      # @api public
      # @example Remove all documents from a collection
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_collection = {
      #     'name' => 'example_1',
      #     'waitForSync' => true,
      #     'id' => 4588,
      #     'status' => 3,
      #     'error' => false,
      #     'code' => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new(database, raw_collection)
      #   collection.truncate!
      def truncate!
        send_command_to_server(:truncate)
      end

      # Fetch a certain document by its key
      #
      # @param [Integer] document_key the key of the document
      # @raise [DocumentNotFoundException] If the requested document was not found
      # @return Document
      # @api public
      # @example Fetch the document with the key 12345
      #   document = collection.fetch(12345)
      def fetch(document_key)
        response = send_request_for_content_key(document_key)
        @content_class.new(@database, response)
      end

      # Fetch a certain document by its key, return nil if the document does not exist
      #
      # @param [Integer] document_key the id of the document
      # @return Document
      # @api public
      # @example Fetch the document with the key 12345
      #   document = collection[12345]
      def [](document_key)
        fetch(document_key)
      rescue DocumentNotFoundException
        nil
      end

      # Replace a document by its key
      #
      # @param [Integer] document_key the key of the document
      # @param [Hash] raw_document the data you want to replace it with
      # @return [Hash] parsed JSON response from the server
      # @api public
      # @example Replace the document with the key 12345
      #   collection.replace(12345, document)
      def replace(document_key, raw_document)
        send_request_for_content_key(document_key, put: raw_document)
      end

      # Create a new document with given attributes
      #
      # @param [Hash] attributes
      # @return [Document] The created document
      # @api public
      # @example Create a new document from raw data
      #   collection.create_document(attributes)
      def create_document(attributes)
        raise "Can't create a document in an edge collection" if @content_type == :edge
        response = send_request_for_content(post: attributes)
        Document.new(@database, response, attributes)
      end

      # Create a new edge between two documents with certain attributes
      #
      # @param [Document] from
      # @param [Document] to
      # @param [Hash] attributes
      # @return [Edge] The created edge
      # @api public
      # @example Create a new document from raw data
      #   collection.create_edge(node_a, node_b, {'name' => 'incredible edge'})
      def create_edge(from, to, attributes)
        raise "Can't create an edge in a document collection" if @content_type == :document
        response = send_request("edge?collection=#{@id}&from=#{from.id}&to=#{to.id}", post: attributes)
        Edge.new(@database, response, attributes)
      end

      # Add an index to the collection
      #
      # @param [Symbol] type specify the type of the index, for example `:hash`
      # @option options [Array<Symbol>] on fields on which to apply the index
      # @option options [Boolean] unique Should the index be unique? Default is false
      # @return Index
      # @api public
      # @example Add a hash-index to the fields :name and :profession of a collection
      #   people = database['people']
      #   people.add_index(:hash, :on => [:name, :profession])
      def add_index(type, options)
        unique = options.fetch(:unique, false)
        response = send_request("index?collection=#{@id}", post: {
          'type' => type.to_s,
          'fields' => options.fetch(:on).map { |field| field.to_s },
          'unique' => unique
        })

        Index.new(self, response)
      end

      # Get an index by ID
      #
      # @param [Integer] id
      # @return Index
      # @api public
      # @example Get an Index by its ID
      #   people = database['people']
      #   people.index(1244) #=> #<Index: id=1244...>
      def index(id)
        response = send_request("index/#{@name}/#{id}")
        Index.new(self, response)
      end

      # Get all indices
      #
      # @return [Array<Index>]
      # @api public
      # @example Get all indices
      #   people = database['people']
      #   people.indices #=> [#<Index: id=1244...>, ...]
      def indices
        response = send_request("index?collection=#{@id}")

        response['indexes'].map do |raw_index|
          Index.new(self, raw_index)
        end
      end

      # Return a Query initialized with this collection
      #
      # @return [Query]
      # @api public
      # @example Get all documents in this collection
      #   people = database['people']
      #   people.query.all #=> #<Cursor: id=1244...>
      def query
        Query.new(self)
      end

      # Check if the collection is volatile
      #
      # @return [Boolean]
      # @api public
      # @example Is the people collection volatile?
      #   people = database['people']
      #   people.volatile? #=> false
      def volatile?
        get_information_from_server(:properties, :isVolatile)
      end

      private

      # Send a put request with a given key and value to the server
      #
      # @param [Symbol] path
      # @param [Symbol] key
      # @param [Symbol] value
      # @return [Object] The result
      # @api private
      def send_information_to_server(path, key, value)
        send_request_for_this_collection("#{path}", put: { key.to_s => value })
      end

      # Send a put request with the given command
      #
      # @param [Symbol] command The command you want to execute
      # @return [Object] The result
      # @api private
      def send_command_to_server(command)
        send_request_for_this_collection("#{command}", put: {})
      end

      # Send a get request to the server and return a certain attribute
      #
      # @param [Symbol] path The path without trailing slash
      # @param [Symbol] attribute The attribute of the answer that should be returned
      # @return [Object] The result
      # @api private
      def get_information_from_server(path, attribute)
        response = send_request_for_this_collection("#{path}")
        response[attribute.to_s]
      end

      # Send a request to the server with the name of the collection prepended
      #
      # @return [String] Response from the server
      # @api private
      def send_request_for_this_collection(path, method = {})
        send_request("collection/#{id}/#{path}", method)
      end

      # Parse information returned from the server
      #
      # @param [Hash] raw_collection
      # @return self
      # @api private
      def parse_raw_collection(raw_collection)
        @name         = raw_collection['name']
        @id           = raw_collection['id']
        @content_type = CONTENT_TYPES[raw_collection['type']] || :document
        @status       = Status.new(raw_collection['status'].to_i) if raw_collection.key?('status')
        self
      end

      # Send a request for the content with the given key
      #
      # @param [Integer] document_id The id of the document
      # @param [Hash] opts The options for the request
      # @return [Hash] parsed JSON response from the server
      # @api private
      def send_request_for_content_key(document_key, opts = {})
        send_request("#{@content_type}/#{@id}/#{document_key}", opts)
      end

      # Send a request for the content of this collection
      #
      # @param [Hash] opts The options for the request
      # @return [Hash] parsed JSON response from the server
      # @api private
      def send_request_for_content(opts = {})
        send_request("#{@content_type}?collection=#{@id}", opts)
      end
    end
  end
end
