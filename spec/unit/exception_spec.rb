# -*- encoding : utf-8 -*-
require 'unit/spec_helper'

require 'ashikawa-core/exceptions/no_collection_provided'
require 'ashikawa-core/exceptions/client_error'
require 'ashikawa-core/exceptions/client_error/authentication_failed'
require 'ashikawa-core/exceptions/client_error/bad_syntax'
require 'ashikawa-core/exceptions/client_error/resource_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/document_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/collection_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/collection_not_in_graph'
require 'ashikawa-core/exceptions/client_error/resource_not_found/index_not_found'
require 'ashikawa-core/exceptions/client_error/resource_not_found/graph_not_found'
require 'ashikawa-core/exceptions/server_error'
require 'ashikawa-core/exceptions/server_error/json_error'

describe Ashikawa::Core::NoCollectionProvidedException do
  its(:to_s) { should include 'without a collection' }
end

describe Ashikawa::Core::ClientError do
  subject { Ashikawa::Core::ClientError.new }
  its(:to_s) { should eq('400 Bad Request') }

  context 'with custom message' do
    let(:error_message) { 'The client did not do what it should do' }
    subject { Ashikawa::Core::ClientError.new(error_message) }
    its(:to_s) { should eq(error_message) }
  end
end

describe Ashikawa::Core::BadSyntax do
  let(:error_message) { 'foo' }
  let(:bad_syntax) { Ashikawa::Core::BadSyntax.new(error_message) }
  it 'accepts an error message to be included in to_s' do
    expect(bad_syntax.to_s).to include error_message
  end
end

describe Ashikawa::Core::AuthenticationFailed do
  its(:to_s) { should include 'Authentication failed' }
end

describe Ashikawa::Core::ResourceNotFound do
  its(:to_s) { should include 'was not found' }
end

describe Ashikawa::Core::DocumentNotFoundException do
  its(:to_s) { should include 'does not exist' }
end

describe Ashikawa::Core::CollectionNotFoundException do
  its(:to_s) { should include 'does not exist' }
end

describe Ashikawa::Core::IndexNotFoundException do
  its(:to_s) { should include 'does not exist' }
end

describe Ashikawa::Core::GraphNotFoundException do
  its(:to_s) { should include 'does not exist' }
end

describe Ashikawa::Core::CollectionNotInGraphException do
  its(:to_s) { should include 'not been added to the graph yet' }
end

describe Ashikawa::Core::ServerError do
  let(:error_message) { 'The server is misbehaving' }
  subject { Ashikawa::Core::ServerError.new(error_message) }
  its(:to_s) { should be(error_message) }
end

describe Ashikawa::Core::JsonError do
  its(:to_s) { should include 'JSON from the server' }
end
