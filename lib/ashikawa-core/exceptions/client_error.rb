# -*- encoding : utf-8 -*-
module Ashikawa
  module Core
    # The client had an error in the request
    class ClientError < RuntimeError
      # Create a new instance
      #
      # @param [String] message The error message
      # @return RuntimeError
      # @api private
      def initialize(message = nil)
        super(message || default_error_message)
      end

      # The default error message to be used. Can be overridden by sub classed
      #
      # @return String the default error message
      # @api private
      def default_error_message
        '400 Bad Request'
      end
    end
  end
end
