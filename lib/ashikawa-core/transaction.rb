# -*- encoding : utf-8 -*-
module Ashikawa
  module Core
    # A JavaScript Transaction on the database
    class Transaction
      # The collections the transaction writes to
      #
      # @return [Array<String>]
      # @api public
      # @example Get the collections that the transaction writes to
      #   transaction.write_collections # => ['collection_1']
      def write_collections
        @request_parameters[:collections][:write]
      end

      # The collections the transaction reads from
      #
      # @return [Array<String>]
      # @api public
      # @example Get the collections that the transaction reads from
      #   transaction.read_collections # => ['collection_1']
      def read_collections
        @request_parameters[:collections][:read]
      end

      # If set to true, the transaction will write all data to disk before returning
      #
      # @return [Boolean]
      # @api public
      # @example Check, if the transaction waits for sync
      #   transaction.wait_for_sync #=> false
      def wait_for_sync
        @request_parameters[:waitForSync]
      end

      # If set to true, the transaction will write all data to disk before returning
      #
      # @param [Boolean] wait_for_sync
      # @api public
      # @example Activate wait sync
      #   transaction.wait_for_sync = true
      def wait_for_sync=(wait_for_sync)
        @request_parameters[:waitForSync] = wait_for_sync
      end

      # An optional numeric value used to set a timeout for waiting on collection locks
      #
      # @return [Integer]
      # @api public
      # @example Check how long the lock timeout is
      #   transaction.lock_timeout # => 30
      def lock_timeout
        @request_parameters[:lockTimeout]
      end

      # An optional numeric value used to set a timeout for waiting on collection locks
      #
      # @param [Integer] lock_timeout
      # @api public
      # @example Set the lock timeout to 30
      #   transaction.lock_timeout = 30
      def lock_timeout=(timeout)
        @request_parameters[:lockTimeout] = timeout
      end

      # Initialize a Transaction
      #
      # @param [Database] database
      # @param [String] action An action written in JavaScript
      # @option options [Array<String>] :write The collections you want to write to
      # @option options [Array<String>] :read The collections you want to read from
      # @api public
      # @example Create a Transaction
      #   transaction = Ashikawa::Core::Transaction.new(database, 'function () { return 5; }',
      #     :read => ['collection_1']
      def initialize(database, action, options)
        @database = database
        @request_parameters = {
          action: action,
          collections: options,
          waitForSync: false
        }
      end

      # Execute the transaction
      #
      # @param [Object] action_params The parameters for the defined action
      # @return Object The result of the transaction
      # @api public
      # @example Run a Transaction
      #   transaction.execute({ :a => 5 })
      def execute(action_parameters = :no_params_provided)
        @request_parameters[:params] = action_parameters unless action_parameters == :no_params_provided
        response = @database.send_request('transaction', post: @request_parameters)
        response['result']
      end
    end
  end
end
