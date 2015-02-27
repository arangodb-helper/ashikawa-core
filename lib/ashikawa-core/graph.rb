# -*- encoding : utf-8 -*-

require 'ashikawa-core/vertex_collection'
require 'ashikawa-core/edge_collection'

module Ashikawa
  module Core
    # A certain graph in the database.
    #
    # @note All CRUD operations on related collections (edges and vertices) must be performed
    #       through their corresponding graph class. Not doing so will eventually lead to inconsistency
    #       and data corruption.
    # @see http://docs.arangodb.com/HttpGharial/README.html
    class Graph
      extend Forwardable

      # Sending requests is delegated to the database
      def_delegator :@database, :send_request

      # Prepared AQL statement for neighbors function on a specific edge collections
      SPECIFIC_NEIGHBORS_AQL = <<-AQL.gsub(/^[ \t]*/, '')
      FOR n IN GRAPH_NEIGHBORS(@graph, { _key:@vertex_key }, {edgeCollectionRestriction: @edge_collection})
        RETURN n.vertex
      AQL

      # Prepared AQL statement for neighbors function on ALL edge collections
      ALL_NEIGHBORS_AQL = <<-AQL.gsub(/^[ \t]*/, '')
      FOR n IN GRAPH_NEIGHBORS(@graph, { _key:@vertex_key }, {})
        RETURN n.vertex
      AQL

      # The database the Graph belongs to
      #
      # @return [Database] The associated database
      # @api public
      # @example
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_graph = {
      #     'name' => 'example_1',
      #     'edgeDefinitions' => [],
      #     'orphanCollections' => []
      #   }
      #   graph = Ashikawa::Core::Graph.new(database, raw_collection)
      #   graph.database #=> #<Database: ...>
      attr_reader :database

      # The name of the graph
      #
      # @return [String] The name of the graph
      # @api public
      # @example
      #   database = Ashikawa::Core::Database.new('http://localhost:8529')
      #   raw_graph = {
      #     'name' => 'example_1',
      #     'edgeDefinitions' => [],
      #     'orphanCollections' => []
      #   }
      #   graph = Ashikawa::Core::Graph.new(database, raw_collection)
      #   graph.name #=> 'example_1
      attr_reader :name

      # The revision of the Graph
      #
      # @return [String] The revision of the Graph
      # @api public
      attr_reader :revision

      # The edge definitions for this Graph
      #
      # @return [Hash] The edge definitons of this Graph as a simple data structure
      # @api public
      attr_reader :edge_definitions

      # Initialize a new graph instance
      #
      # @param [Database] database A reference to the database this graph belongs to
      # @param [Hash] raw_graph The parsed JSON response from the database representing the graph
      def initialize(database, raw_graph)
        @database = database
        parse_raw_graph(raw_graph)
      end

      def delete(options = {})
        drop_collections = options.fetch(:drop_collections) { false }
        send_request("gharial/#@name", delete: { dropCollections: drop_collections })
      end

      # Gets a list of vertex collections
      #
      # Due to the fact we need to fetch each of the collections by hand this will just return an
      # enumerator which will lazily fetch the collections from the database.
      #
      # @return [Enumerator] An Enumerator referencing the vertex collections
      def vertex_collections
        Enumerator.new do |yielder|
          vertex_collection_names.each do |collection_name|
            yielder.yield vertex_collection(collection_name)
          end
        end
      end

      # The list of names of the vertex collections
      #
      # @return [Array] Names of all vertex collections
      def vertex_collection_names
        @orphan_collections | @edge_definitions.map { |edge_def| edge_def.values_at('from', 'to') }.flatten
      end

      # Adds a vertex collection to this graph
      #
      # If the collection does not yet exist it will be created. If it already exists it will just be added
      # to the list of vertex collections.
      #
      # @param [String] collection_name The name of the vertex collection
      # @see Graph#add_vertex_collection! if you need to know if the collection is already present
      # @return [VertexCollection] The newly created collection
      def add_vertex_collection(collection_name)
        add_vertex_collection!(collection_name)
      rescue Ashikawa::Core::VertexCollectionAlreadyPresent
        vertex_collection(collection_name)
      end

      # Adds a vertex collection to this graph
      #
      # If the collection does not exist yet it will be created. Initially it will add it as an orphaned
      # collection to the graph. If the collection is already present in the graph definition, either as
      # an orphan or as part of an edge definition an error is raised.
      #
      # @param [String] collection_name The name of the vertex collection
      # @raise [Ashikawa::Core::VertexCollectionAlreadyPresent] if the collection is already part of the graph
      # @see Graph#add_vertex_collection if you want to silently ignore the exception
      # @return [VertexCollection] The newly created collection
      def add_vertex_collection!(collection_name)
        response = send_request("gharial/#@name/vertex", post: { collection: collection_name })
        parse_raw_graph(response['graph'])
        vertex_collection(collection_name)
      end

      # Fetches a vertex collection associated with graph from the database
      #
      # @param [String] collection_name The name of the collection
      # @return [VertexCollection] The fetched VertexCollection
      def vertex_collection(collection_name)
        raw_collection = send_request("collection/#{collection_name}")
        VertexCollection.new(database, raw_collection, self)
      end

      # Checks if a collection is present in the list of vertices
      #
      # @param [String] collection_name The name of the collection to query
      # @return [Boolean] True if the collection is present, false otherwise
      def has_vertex_collection?(collection_name)
        vertex_collection_names.any? { |name| name == collection_name }
      end

      # Gets a list of edge collections
      #
      # Due to the fact we need to fetch each of the collections by hand this will just return an
      # enumerator which will lazily fetch the collections from the database.
      #
      # @return [Enumerator] An Enumerator referencing the edge collections
      def edge_collections
        Enumerator.new do |yielder|
          edge_collection_names.each do |collection_name|
            yielder.yield edge_collection(collection_name)
          end
        end
      end

      # The list of names of the edge collections
      #
      # @return [Array] Names of all edge collections
      def edge_collection_names
        @edge_definitions.map { |edge_def| edge_def['collection'] }
      end

      # Adds an edge definition to this Graph
      #
      # If the edge definition doesn't exist it will be created, else it will just return the edge
      # collection.
      #
      # @param [Symbol] collection_name The name of the resulting edge collection
      # @param [Hash] directions The specification between which vertices the edges should be created
      # @option [Array<Symbol>] :from A list of collections names from which the edge directs
      # @option [Array<Symbol>] :to A list of collections names to which the edge directs
      # @see Graph@add_edge_definition! if you need to know the edge definition was already present
      # @return [EdgeCollection] The edge collection used be the definition
      def add_edge_definition(collection_name, directions)
        add_edge_definition!(collection_name, directions)
      rescue Ashikawa::Core::EdgeCollectionAlreadyPresent
        edge_collection(collection_name)
      end

      # Adds an edge definition to this Graph
      #
      # If the edge definition doesn't exist it will be created, else it will raise an error.
      #
      # @param [Symbol] collection_name The name of the resulting edge collection
      # @param [Hash] directions The specification between which vertices the edges should be created
      # @option [Array<Symbol>] :from A list of collections names from which the edge directs
      # @option [Array<Symbol>] :to A list of collections names to which the edge directs
      # @raise Ashikawa::Core::EdgeCollectionAlreadyPresent if the edge definition is already defined
      # @see Graph#add_edge_definition if you need an idempotent version of this
      # @return [EdgeCollection] The edge collection used be the definition
      def add_edge_definition!(collection_name, directions)
        create_options = {
          collection: collection_name,
          from:       directions[:from],
          to:         directions[:to]
        }

        response = send_request("gharial/#@name/edge", post: create_options)
        parse_raw_graph(response['graph'])
        edge_collection(collection_name)
      end

      # Fetches an edge collection from the database
      #
      # @param [String] collection_name The name of the desired edge
      # @return [EdgeCollection] The edge collection for the given name
      def edge_collection(collection_name)
        response = send_request("collection/#{collection_name}")
        EdgeCollection.new(database, response, self)
      end

      # Return a Cursor representing the neighbors for the given document and optional edge collections
      #
      # @param [Document] vertex The start vertex
      # @param [options] options Additional options like restrictions on the edge collections
      # @option [Array<Symbol>] :edges A list of edge collection to restrict the neighbors function on
      # @return [Cursor] The cursor to the query result
      def neighbors(vertex, options = {})
        bind_vars = {
          graph: name,
          vertex_key: vertex.key
        }
        aql_string = ALL_NEIGHBORS_AQL

        if options.has_key?(:edges)
          aql_string = SPECIFIC_NEIGHBORS_AQL
          bind_vars[:edge_collection] = [options[:edges]].flatten
        end

        database.query.execute(aql_string, bind_vars: bind_vars)
      end

      private

      # Parses the raw graph structure as returned from the database
      #
      # @param [Hash] raw_graph The structure as returned from the database
      # @api private
      def parse_raw_graph(raw_graph)
        @name               = raw_graph['name'] || raw_graph['_key']
        @revision           = raw_graph['_rev']
        @edge_definitions   = raw_graph.fetch('edgeDefinitions') { [] }
        @orphan_collections = raw_graph.fetch('orphanCollections') { [] }
      end
    end
  end
end
