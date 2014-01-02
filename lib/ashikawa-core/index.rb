# -*- encoding : utf-8 -*-
require 'equalizer'

module Ashikawa
  module Core
    # An index on a certain collection
    class Index
      include Equalizer.new(:id, :on, :type, :unique)

      # The fields the index is defined on as symbols
      #
      # @return [Array<Symbol>]
      # @api public
      # @example Get the fields the index is set on
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      #   index.fields #=> [:name]
      attr_reader :on

      # The type of index as a symbol
      #
      # @return [Symbol]
      # @api public
      # @example Get the type of the index
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      #   index.type #=> :skiplist
      attr_reader :type

      # Is the unique constraint set?
      #
      # @return [Boolean]
      # @api public
      # @example Get the fields the index is set on
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      #   index.unique #=> false
      attr_reader :unique

      # The ID of the index (includes a Collection prefix)
      #
      # @return [String]
      # @api public
      # @example Get the id of this index
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      #   index.id #=> 4567
      attr_reader :id

      # Create a new Index
      #
      # @param [Collection] collection The collection the index is defined on
      # @param [Hash] raw_index The JSON representation of the index
      # @return [Index]
      # @api public
      # @example Create a new index from the raw representation
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      def initialize(collection, raw_index)
        @collection = collection
        @id = raw_index['id']
        @on = convert_to_symbols(raw_index['fields'])
        @type = raw_index['type'].to_sym
        @unique = raw_index['unique']
      end

      # Remove the index from the collection
      #
      # @return [Hash] parsed JSON response from the server
      # @api public
      # @example Remove this index from the collection
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      #   index.delete
      def delete
        @collection.send_request("index/#{@id}", delete: {})
      end

      private

      # Convert all elements of an array to symbols
      #
      # @param [Array] arr
      # @return Array
      # @api private
      def convert_to_symbols(arr)
        arr.map { |field| field.to_sym }
      end
    end
  end
end
