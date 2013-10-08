# -*- encoding : utf-8 -*-
require 'ashikawa-core/connection'

module Ashikawa
  module Core
    # Configuration of Ashikawa::Core
    class Configuration
      # The URL of the database instance
      # @api private
      # @return String
      attr_accessor :url

      # The Connection object
      # @api private
      # @return Connection
      attr_writer :connection

      # The logger instance
      # @api private
      # @return Object
      attr_accessor :logger

      # The HTTP adapter instance
      # @api private
      # @return Object
      attr_accessor :adapter

      # The Connection object
      # @api private
      # @return Connection
      def connection
        @connection || setup_new_connection
      end

      private

      # Setup the connection object
      #
      # @param [String] url
      # @param [Logger] logger
      # @param [Adapter] adapter
      # @return [Connection]
      # @api private
      def setup_new_connection
        raise(ArgumentError, 'Please provide either an url or a connection to setup the database') if url.nil?
        Ashikawa::Core::Connection.new(url, {
          logger: logger,
          adapter: adapter
        })
      end
    end
  end
end
