require "faraday"
require "json"
require "ashikawa-core/exceptions/client_error"
require "ashikawa-core/exceptions/client_error/resource_not_found"
require "ashikawa-core/exceptions/client_error/resource_not_found/index_not_found"
require "ashikawa-core/exceptions/client_error/resource_not_found/document_not_found"
require "ashikawa-core/exceptions/client_error/resource_not_found/collection_not_found"
require "ashikawa-core/exceptions/client_error/bad_syntax"
require "ashikawa-core/exceptions/server_error"
require "ashikawa-core/exceptions/server_error/json_error"

module Ashikawa
  module Core
    # Preprocessor for Faraday Requests
    class ResponsePreprocessor < Faraday::Middleware
      ClientErrorStatuses = 400...499
      ServerErrorStatuses = 500...599
      BadSyntaxStatus = 400
      ResourceNotFoundErrorError = 404

      # Create a new Response Preprocessor
      #
      # @param [Object] app Faraday internal
      # @param [Object] logger The object you want to log to
      # @return [ResponsePreprocessor]
      # @api private
      def initialize(app, logger)
        @app = app
        @logger = logger
      end

      # Process a Response
      #
      # @param [Hash] env Environment info
      # @return [Object]
      # @api private
      def call(env)
        @app.call(env).on_complete do
          log(env)
          handle_status(env)
          env[:body] = parse_json(env)
        end
      end

      private

      # Raise the fitting ResourceNotFoundException
      #
      # @raise [DocumentNotFoundException, CollectionNotFoundException, IndexNotFoundException]
      # @return nil
      # @api private
      def resource_not_found_for(env)
        raise case env[:url].path
              when /\A\/_api\/document/ then Ashikawa::Core::DocumentNotFoundException
              when /\A\/_api\/collection/ then Ashikawa::Core::CollectionNotFoundException
              when /\A\/_api\/index/ then Ashikawa::Core::IndexNotFoundException
              else Ashikawa::Core::ResourceNotFound
        end
      end

      # Parse the JSON
      #
      # @param [Hash] env Environment info
      # @return [Hash] The parsed body
      # @api private
      def parse_json(env)
        raise JSON::ParserError unless json_content_type?(env[:response_headers]["content-type"])
        JSON.parse(env[:body])
      rescue JSON::ParserError
        raise Ashikawa::Core::JsonError
      end

      # Check if the Content Type is JSON
      #
      # @param [String] content_type
      # @return [Boolean]
      # @api private
      def json_content_type?(content_type)
        content_type == "application/json; charset=utf-8"
      end

      # Handle the status code
      #
      # @param [Hash] env Environment info
      # @return [nil]
      # @api private
      def handle_status(env)
        case env[:status]
        when BadSyntaxStatus then raise Ashikawa::Core::BadSyntax
        when ResourceNotFoundErrorError then raise resource_not_found_for(env)
        when ClientErrorStatuses then raise Ashikawa::Core::ClientError, error(env[:body])
        when ServerErrorStatuses then raise Ashikawa::Core::ServerError, error(env[:body])
        end
      end

      # Log a Request
      #
      # @param [Hash] env Environment info
      # @return [nil]
      # @api private
      def log(env)
        @logger.info("#{env[:status]} #{env[:body]}")
        nil
      end

      # Read the error message for the request
      #
      # @param [String] The raw body of the request
      # @return [String] The formatted error message
      # @api private
      def error(body)
        parsed_body = JSON.parse(body)
        "#{parsed_body["errorNum"]}: #{parsed_body["errorMessage"]}"
      end
    end

    Faraday.register_middleware :response,
      :ashikawa_response => lambda { ResponsePreprocessor}
  end
end
