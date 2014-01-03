# -*- encoding : utf-8 -*-
require 'ashikawa-core/document'
require 'equalizer'

module Ashikawa
  module Core
    # A certain Edge within a certain Collection
    class Edge < Document
      include Equalizer.new(:id, :revision, :from_id, :to_id)

      # The ID of the 'from' document
      #
      # @return [String]
      # @api public
      # @example Get the ID for the 'from' Document
      #   document = Ashikawa::Core::Edge.new(database, raw_document)
      #   document.from_id # => 'my_fancy_collection/2345678'
      attr_reader :from_id

      # The ID of the 'to' document
      #
      # @return [String]
      # @api public
      # @example Get the ID for the 'to' Document
      #   document = Ashikawa::Core::Edge.new(database, raw_document)
      #   document.to_id # => 'my_fancy_collection/2345678'
      attr_reader :to_id

      # Initialize an Edge with the database and raw data
      #
      # @param [Database] _database
      # @param [Hash] raw_edge
      # @param [Hash] _additional_data
      # @api public
      # @example Create an Edge
      #   document = Ashikawa::Core::Edge.new(database, raw_edge)
      def initialize(_database, raw_edge, _additional_data = {})
        @from_id = raw_edge['_from']
        @to_id = raw_edge['_to']
        super
      end

      protected

      # Send a request for this edge with the given opts
      #
      # @param [Hash] opts Options for this request
      # @return [Hash] The parsed response from the server
      # @api private
      def send_request_for_document(opts)
        @database.send_request("edge/#{@id}", opts)
      end
    end
  end
end
