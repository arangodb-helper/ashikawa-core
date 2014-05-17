# -*- encoding : utf-8 -*-
module Ashikawa
  module Core
    # Wrapper around the status of a collection
    class Status
      # ArangoDB Status for a new born collection
      STATUS_NEW_BORN       = 1

      # ArangoDB Status for a collection that is unloaded
      STATUS_UNLOADED       = 2

      # ArangoDB Status for a collection that is loaded
      STATUS_LOADED         = 3

      # ArangoDB Status for a collection that is being unloaded
      STATUS_BEING_UNLOADED = 4

      # Highest ArangoDB Status that means that the collection is not corrupted
      MAX_UNCORRUPTED       = 5

      # Create a wrapper around a given status
      #
      # @param [Fixnum] code
      # @api public
      # @example Create a new status
      #   status = Ashikawa::Core::Status.new(3)
      def initialize(code)
        @code = code
      end

      # Checks if the collection is new born
      #
      # @return [Boolean]
      # @api public
      # @example Is the collection new born?
      #   status = Ashikawa::Core::Status.new(3)
      #   status.new_born? #=> false
      def new_born?
        @code.equal?(STATUS_NEW_BORN)
      end

      # Checks if the collection is unloaded
      #
      # @return [Boolean]
      # @api public
      # @example Is the collection unloaded?
      #   status = Ashikawa::Core::Status.new(3)
      #   status.unloaded? #=> false
      def unloaded?
        @code.equal?(STATUS_UNLOADED)
      end

      # Checks if the collection is loaded
      #
      # @return [Boolean]
      # @api public
      # @example Is the collection loaded?
      #   status = Ashikawa::Core::Status.new(3)
      #   status.loaded? #=> true
      def loaded?
        @code.equal?(STATUS_LOADED)
      end

      # Checks if the collection is in the process of being unloaded
      #
      # @return [Boolean]
      # @api public
      # @example Is the collection unloaded?
      #   status = Ashikawa::Core::Status.new(3)
      #   status.being_unloaded? #=> false
      def being_unloaded?
        @code.equal?(STATUS_BEING_UNLOADED)
      end

      # Checks if the collection is corrupted
      #
      # @return [Boolean]
      # @api public
      # @example Is the collection corrupted?
      #   status = Ashikawa::Core::Status.new(3)
      #   status.corrupted? #=> false
      def corrupted?
        @code > MAX_UNCORRUPTED
      end
    end
  end
end
