# -*- encoding : utf-8 -*-
require "ashikawa-core/exceptions/no_collection_provided"
require "ashikawa-core/exceptions/client_error"
require "ashikawa-core/exceptions/client_error/bad_syntax"
require "ashikawa-core/exceptions/client_error/resource_not_found"
require "ashikawa-core/exceptions/client_error/resource_not_found/document_not_found"
require "ashikawa-core/exceptions/client_error/resource_not_found/collection_not_found"
require "ashikawa-core/exceptions/client_error/resource_not_found/index_not_found"
require "ashikawa-core/exceptions/server_error"
require "ashikawa-core/exceptions/server_error/json_error"

describe Ashikawa::Core::NoCollectionProvidedException do
  its(:to_s) { should include "without a collection" }
end

describe Ashikawa::Core::ClientError do
  let(:error_message) { double }
  subject { Ashikawa::Core::ClientError.new(error_message) }
  its(:to_s) { should be(error_message) }
end

describe Ashikawa::Core::BadSyntax do
  its(:to_s) { should include "syntax" }
end

describe Ashikawa::Core::ResourceNotFound do
  its(:to_s) { should include "was not found" }
end

describe Ashikawa::Core::DocumentNotFoundException do
  its(:to_s) { should include "does not exist" }
end

describe Ashikawa::Core::CollectionNotFoundException do
  its(:to_s) { should include "does not exist" }
end

describe Ashikawa::Core::IndexNotFoundException do
  its(:to_s) { should include "does not exist" }
end

describe Ashikawa::Core::ServerError do
  let(:error_message) { double }
  subject { Ashikawa::Core::ServerError.new(error_message) }
  its(:to_s) { should be(error_message) }
end

describe Ashikawa::Core::JsonError do
  its(:to_s) { should include "JSON from the server" }
end
