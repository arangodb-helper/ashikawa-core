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
        parse_raw_index(raw_index)
      end

      # Remove the index from the collection
      #
      # @return [Hash] parsed JSON response from the server
      # @api public
      # @example Remove this index from the collection
      #   index = Ashikawa::Core::Index.new(collection, raw_index)
      #   index.delete
      def delete
        @collection.send_request("index/#{@id}", :delete => {})
      end

      private

      # Parse information returned from the server
      #
      # @param [Hash] raw_index
      # @return self
      # @api private
      def parse_raw_index(raw_index)
        @id = raw_index["id"]
        @on = raw_index["fields"].map { |field| field.to_sym } if raw_index.has_key?("fields")
        @type = raw_index["type"].to_sym if raw_index.has_key?("type")
        @unique = raw_index["unique"]
        self
      end
    end
  end
end
