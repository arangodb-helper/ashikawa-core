# -*- encoding : utf-8 -*-

require 'ashikawa-core/exceptions/client_error.rb'

module Ashikawa
  module Core
    # This collection may occur when adding edge definitions
    # to the graph. While creating edge definitions ArangoDB
    # will create an edge collection. It has be unique for the
    # current database. ArangoDB differentiates between two errors:
    #
    #  1. The edge collection is already used in the same graph (1920)
    #  2. The edge collection is already used in another graph (1921)
    class EdgeCollectionAlreadyPresent < ClientError
    end
  end
end
