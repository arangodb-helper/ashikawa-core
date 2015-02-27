# -*- encoding : utf-8 -*-
require 'ashikawa-core/exceptions/client_error.rb'

module Ashikawa
  module Core
    # This Exception is thrown when you request
    # a resource that does not exist on the server
    class ResourceNotFound < ClientError
      # The default message for this error.
      #
      # @return String
      # @api private
      def default_error_message
        'The Resource you requested was not found on the server'
      end
    end
  end
end
