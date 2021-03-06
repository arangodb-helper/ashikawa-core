# -*- encoding : utf-8 -*-
require 'ashikawa-core/exceptions/client_error'
require 'ashikawa-core/exceptions/client_error/resource_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/index_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/document_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/collection_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/graph_not_found'
require 'ashikawa-core/exceptions/client_error/bad_syntax'
require 'ashikawa-core/exceptions/client_error/authentication_failed'
require 'ashikawa-core/exceptions/client_error/vertex_collection_already_present'
require 'ashikawa-core/exceptions/client_error/edge_collection_already_present'
require 'ashikawa-core/exceptions/server_error'
require 'ashikawa-core/exceptions/server_error/json_error'

module Ashikawa
  module Core
    # A response from the server
    class ErrorResponse < Faraday::Response::Middleware
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

      # On completion of the request raise errors depending on the status
      #
      # @raise [BadSyntax] If the status code is a 400
      # @raise [AuthenticationFailed] If the status code is a 401
      # @raise [DocumentNotFoundException] If the status code is 404 and a document was requested
      # @raise [CollectionNotFoundException] If the status code is 404 and a collection was requested
      # @raise [IndexNotFoundException] If the status code is 404 and an index was requested
      # @raise [ResourceNotFoundError] If the status code is 404 and any other resource was requested
      # @raise [ClientError] If the status code is any other 4XX code
      # @raise [ServerError] If the status code is any of the 5XX codes
      # @return nil
      def on_complete(env)
        @body = env[:body] || {}
        @url = env[:url]

        case env[:status]
        when BadSyntaxStatus then bad_syntax
        when AuthenticationFailed then authentication_failed
        when ResourceNotFoundError then resource_not_found
        when ClientErrorStatuses then client_error
        when ServerErrorStatuses then server_error
        end
      end

      private

      # Raise a Bad Syntax Error
      #
      # @raise [BadSyntax]
      # @return nil
      # @api private
      def bad_syntax
        raise BadSyntax, error
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
              when %r{\A(/_db/[^/]+)?/_api/gharial} then resource_not_found_in_graph_scope
              else ResourceNotFound
              end, error
      end

      # Raise fitting ResourceNotFoundException within the Graph module
      #
      # @raise [DocumentNotFoundException, CollectionNotFoundException, GraphNotFoundException, ResourceNotFound]
      # @return nil
      # @api private
      def resource_not_found_in_graph_scope
        raise case @body['errorMessage']
              when 'graph not found' then GraphNotFoundException
              when 'collection not found' then CollectionNotFoundException
              when 'document not found' then DocumentNotFoundException
              when 'collection used in orphans' then VertexCollectionAlreadyPresent
              when 'collection used in edge def' then VertexCollectionAlreadyPresent
              when 'multi use of edge collection in edge def' then EdgeCollectionAlreadyPresent
              when 'edge collection already used in edge def' then EdgeCollectionAlreadyPresent
              else ResourceNotFound
              end, error
      end

      # Read the error message for the request
      #
      # @param [String] The raw body of the request
      # @return [String] The formatted error message
      # @api private
      def error
        @body.empty? ? nil : "#{@body['errorNum']}: #{@body['errorMessage']}"
      end
    end

    Faraday::Response.register_middleware error_response: -> { ErrorResponse }
  end
end
