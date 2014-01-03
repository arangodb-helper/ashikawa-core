require 'json'
require 'ashikawa-core/exceptions/client_error'
require 'ashikawa-core/exceptions/client_error/resource_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/index_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/document_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/collection_not_found'
require 'ashikawa-core/exceptions/client_error/bad_syntax'
require 'ashikawa-core/exceptions/client_error/authentication_failed'
require 'ashikawa-core/exceptions/server_error'
require 'ashikawa-core/exceptions/server_error/json_error'

module Ashikawa
  module Core
    # A response from the server
    class Response
      # Status code for a [Bad Request](http://httpstatus.es/400)
      BadSyntaxStatus = 400

      # Status code for an [Unauthorized Request](http://httpstatus.es/401)
      AuthenticationFailed = 401

      # Status code for a [Not Found Resource](http://httpstatus.es/404)
      ResourceNotFoundError = 404

      # All other status codes for client errors
      ClientErrorStatuses = 405...499

      # All status codes for server errors
      ServerErrorStatuses = 500...599

      def initialize(env)
        @status = env[:status]
        @body = env[:body]
        @url = env[:url]
        @response_headers = env[:response_headers]
        handle_status
      end

      # Parsed version of the body
      #
      # @param [Hash] env Environment info
      # @return [Hash] The parsed body
      # @api private
      def parsed_body
        raise JSON::ParserError unless json_content_type?
        JSON.parse(@body)
      rescue JSON::ParserError
        raise JsonError
      end

      private

      # Handle the status code
      #
      # @param [Hash] env Environment info
      # @return [nil]
      # @api private
      def handle_status
        case @status
        when BadSyntaxStatus then bad_syntax
        when AuthenticationFailed then authentication_failed
        when ResourceNotFoundError then resource_not_found
        when ClientErrorStatuses then client_error
        when ServerErrorStatuses then server_error
        end
      end

      # Check if the Content Type is JSON
      #
      # @param [String] content_type
      # @return [Boolean]
      # @api private
      def json_content_type?
        @response_headers['content-type'] == 'application/json; charset=utf-8'
      end

      # Raise a Bad Syntax Error
      #
      # @raise [BadSyntax]
      # @return nil
      # @api private
      def bad_syntax
        raise BadSyntax
      end

      # Raise an Authentication Failed Error
      #
      # @raise [AuthenticationFailed]
      # @return nil
      # @api private
      def authentication_failed
        raise Core::AuthenticationFailed
      end

      # Raise a Client Error for a given body
      #
      # @raise [ClientError]
      # @return nil
      # @api private
      def client_error
        raise ClientError, error
      end

      # Raise a Server Error for a given body
      #
      # @raise [ServerError]
      # @return nil
      # @api private
      def server_error
        raise ServerError, error
      end

      # Raise the fitting ResourceNotFoundException
      #
      # @raise [DocumentNotFoundException, CollectionNotFoundException, IndexNotFoundException]
      # @return nil
      # @api private
      def resource_not_found
        raise case @url.path
              when %r{\A(/_db/[^/]+)?/_api/document} then DocumentNotFoundException
              when %r{\A(/_db/[^/]+)?/_api/collection} then CollectionNotFoundException
              when %r{\A(/_db/[^/]+)?/_api/index} then IndexNotFoundException
              else ResourceNotFound
        end
      end

      # Read the error message for the request
      #
      # @param [String] The raw body of the request
      # @return [String] The formatted error message
      # @api private
      def error
        parsed_body = JSON.parse(@body)
        "#{parsed_body['errorNum']}: #{parsed_body["errorMessage"]}"
      end
    end
  end
end
