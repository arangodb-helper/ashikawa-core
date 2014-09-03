# -*- encoding : utf-8 -*-

module Ashikawa
  module Core
    # A certain graph in the database.
    #
    # @note All CRUD operations on related collections (edges and vertices) must be performed
    #       through their corresponding graph class. Not doing so will eventually lead to inconsistency
    #       and data corruption.
    class Graph
      extend Forwardable

      # Sending requests is delegated to the database
      def_delegator :@database, :send_request

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

      # The name of the database
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

      # Initialize a new graph instance
      #
      # @param [Database] database A reference to the database this graph belongs to
      # @param [Hash] raw_graph The parsed JSON response from the database representing the graph
      def initialize(database, raw_graph)
        @database = database
        parse_raw_graph(raw_graph)
      end

      # Gets a list of vertex collections
      #
      # Due to the fact we need to fetch each of the collections by hand this will just return an
      # enumerator which will lazily fetch the collections from the database.
      #
      # @return [Enumerator] An Enumerator referencing the vertex collections
      def vertex_collections
        @vertex_collections
      end

      private

      # Parses the raw graph structure as returned from the database
      #
      # @param [Hash] raw_graph The structure as returned from the database
      def parse_raw_graph(raw_graph)
        @name               = raw_graph['name'] || raw_graph['_key']
        @vertex_collections = extract_vertex_collections(raw_graph)
      end

      # Extracts the names of all the vertex collections from the raw graph
      #
      # @param [Hash] raw_graph The structure as returned from the database
      # @return [Array] Names of all vertex collections
      def extract_vertex_collections(raw_graph)
        collections = raw_graph['orphan_collections']

        from_to_keys            = -> (k,v) { k == 'from' || k == 'to' }
        select_from_and_to_keys = -> (hsh) { hsh.select(&from_to_keys)}

        collections += raw_graph['edge_definitions']
          .map(&select_from_and_to_keys)
          .map(&:values)

        collections.flatten.uniq
      end
    end
  end
end
