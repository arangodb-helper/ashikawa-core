module Ashikawa
  module Core
    # Configuration of Ashikawa::Core
    class Configuration < Struct.new(:url, :connection, :logger, :adapter)
      # The URL of the database instance
      # @api private
      # @return String
      attr_accessor :url

      # The Connection object
      # @api private
      # @return Connection
      attr_accessor :connection

      # The logger instance
      # @api private
      # @return Object
      attr_accessor :logger

      # The HTTP adapter instance
      # @api private
      # @return Object
      attr_accessor :adapter
    end
  end
end
