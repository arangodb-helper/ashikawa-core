# -*- encoding : utf-8 -*-
require 'faraday'
require 'json'

module Ashikawa
  module Core
    # Preprocessor for Faraday Requests
    class RequestPreprocessor < Faraday::Middleware
      # Create a new Request Preprocessor
      #
      # @param [Object] app Faraday internal
      # @param [Object] logger The object you want to log to
      # @return [RequestPreprocessor]
      # @api private
      def initialize(app, logger)
        @app = app
        @logger = logger
      end

      # Process a Request
      #
      # @param [Hash] env Environment info
      # @return [Object]
      # @api private
      def call(env)
        body = env[:body]
        env[:body] = JSON.generate(body) if body
        log(env[:method], env[:url], body)
        @app.call(env)
      end

      private

      # Log a Request
      #
      # @param [Symbol] method
      # @param [String] url
      # @param [String] body
      # @return [nil]
      # @api private
      def log(method, url, body)
        @logger.debug("#{method.upcase} #{url} #{body}")
        nil
      end
    end

    Faraday.register_middleware :request,
                                ashikawa_request: -> { RequestPreprocessor }
  end
end
