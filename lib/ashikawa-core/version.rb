# -*- encoding : utf-8 -*-
module Ashikawa
  module Core
    # Current version of Ashikawa::Core
    VERSION = '0.14.0'

    # The lowest supported ArangoDB major version
    ARANGODB_MAJOR_VERSION = 2

    # The lowest supported ArangoDB minor version
    ARANGODB_MINOR_VERSION = 2

    def self.api_compatibility_version
      (ARANGODB_MAJOR_VERSION * 10_000 + ARANGODB_MINOR_VERSION * 100).to_s
    end
  end
end
