# -*- encoding : utf-8 -*-
require 'ashikawa-core/collection'
require 'ashikawa-core/edge'

module Ashikawa
  module Core
    # An edge collection as it is returned from a graph
    #
    # @note This is basically just a regular collection with some additional attributes and methods to ease
    #       working with collections in the graph module.
    class EdgeCollection < Collection
      # The Graph instance this EdgeCollection was originally fetched from
      #
      # @return [Graph] The Graph instance the collection was fetched from
      # @api public
      attr_reader :graph

      # Create a new EdgeCollection object
      #
      # @param [Database] database The database the connection belongs to
      # @param [Hash] raw_collection The raw collection returned from the server
      # @param [Graph] graph The graph from which this collection was fetched
      # @note You should not create instance manually but rather use Graph#add_edge_definition
      # @api public
      def initialize(database, raw_collection, graph)
        super(database, raw_collection)
        @graph = graph
      end

      # Create one or more edges between documents with certain attributes
      #
      # @param [Document, Array<Document>] from One or more documents to connect from
      # @param [Document, Array<Document>] to One ore more documents to connect to
      # @param [Hash] attributes Additional attributes to add to all created edges
      # @return [Array<Edge>] A list of all created edges
      # @api public
      # @example Create an edge between two vertices
      #   edges = edge_collection.add(from: vertex_a, to: vertex_b)
      # @example Create multiple edges between vertices
      #   edges = edge_collection.add(from: vertex_a, to: [vertex_b, vertex_c])
      # @example Create an edge with additional attributes
      #   edges = edge_collection.add(from: vertex_a, to: vertex_b, { type: 'connection', weight: 10 })
      def add(directions)
        product = -> (v, *rest) { [v].flatten.compact.product(rest.flatten.compact) }

        from_to = product.call(directions[:from], directions[:to])

        from_to.each do |from_vertex, to_vertex|
          send_request("gharial/#{graph.name}/edge/#@name", post: { _from: from_vertex.id, _to: to_vertex.id })
        end
      end
    end
  end
end