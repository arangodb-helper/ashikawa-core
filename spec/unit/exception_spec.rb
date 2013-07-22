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
  it "should have a good explanation" do
    subject.to_s.should include "without a collection"
  end
end

describe Ashikawa::Core::ClientError do
  let(:error_message) { "error message" }
  it "should have a good explanation" do
    Ashikawa::Core::ClientError.new(error_message).to_s.should == error_message
  end
end

describe Ashikawa::Core::BadSyntax do
  it "should have a good explanation" do
    subject.to_s.should include "syntax"
  end
end

describe Ashikawa::Core::ResourceNotFound do
  it "should have a good explanation" do
    subject.to_s.should include "was not found"
  end
end

describe Ashikawa::Core::DocumentNotFoundException do
  it "should have a good explanation" do
    subject.to_s.should include "does not exist"
  end
end

describe Ashikawa::Core::CollectionNotFoundException do
  it "should have a good explanation" do
    subject.to_s.should include "does not exist"
  end
end

describe Ashikawa::Core::IndexNotFoundException do
  it "should have a good explanation" do
    subject.to_s.should include "does not exist"
  end
end

describe Ashikawa::Core::ServerError do
  let(:error_message) { "error message" }
  it "should have a good explanation" do
    Ashikawa::Core::ServerError.new(error_message).to_s.should == error_message
  end
end

describe Ashikawa::Core::JsonError do
  it "should have a good explanation" do
    subject.to_s.should include "JSON from the server"
  end
end
