module Ashikawa
  module Core
    # Options for controlling keys of a collection
    class KeyOptions
      # Either traditional or autoincrement
      #
      # @return Symbol
      # @api public
      # @example Get the type of the KeyOptions
      #   keyOptions = KeyOptions.new({ :type => :autoincrement })
      #   keyOptions.type # => :autoincrement
      attr_reader :type

      # A specific start value
      #
      # @return Integer
      # @api public
      # @example Get the type of the KeyOptions
      #   keyOptions = KeyOptions.new({ :offset => 12 })
      #   keyOptions.offset # => 12
      attr_reader :offset

      # Size of increment steps
      #
      # @return Integer
      # @api public
      # @example Get the type of the KeyOptions
      #   keyOptions = KeyOptions.new({ :increment => 12 })
      #   keyOptions.increment # => 12
      attr_reader :increment

      # Is the user allowed to set keys by him- or herself?
      #
      # @return Boolean
      # @api public
      # @example Get the type of the KeyOptions
      #   keyOptions = KeyOptions.new({ :allowUserKeys => true })
      #   keyOptions.allow_user_keys # => true
      attr_reader :allow_user_keys

      # Create a new KeyOptions object from the raw key options
      #
      # @api public
      # @example Create a new KeyOptions object
      #   KeyOptions.new({ :type => :autoincrement })
      def initialize(raw_key_options)
        @type = raw_key_options["type"]
        @offset = raw_key_options["offset"]
        @increment = raw_key_options["increment"]
        @allow_user_keys = raw_key_options["allowUserKeys"]
      end
    end
  end
end
