# -*- encoding : utf-8 -*-

require 'ashikawa-core/exceptions/client_error.rb'

module Ashikawa
  module Core
    # This exception is thrown when the vertex collection
    # to be added is already member of the graph. There are
    # two different error messages that can occur:
    #
    #  1. The vertex collection is already member of the orphans (1938)
    #  2. The vertex collection is already member of an edge definition (1929)
    class VertexCollectionAlreadyPresent < ClientError
    end
  end
end
