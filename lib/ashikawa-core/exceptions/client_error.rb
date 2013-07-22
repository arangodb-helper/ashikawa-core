module Ashikawa
  module Core
    # The client had an error in the request
    class ClientError < RuntimeError
      # Create a new instance
      #
      # @param [Integer] status
      # @return RuntimeError
      # @api private
      def initialize(description)
        @description = description
      end

      # String representation of the exception
      #
      # @return String
      # @api private
      def to_s
        @description
      end
    end
  end
end
