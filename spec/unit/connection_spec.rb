require 'unit/spec_helper'
require 'ashikawa-core/connection'

describe Ashikawa::Core::Connection do
  subject { Ashikawa::Core::Connection }

  it "should have an IP and port" do
    connection = subject.new "http://localhost:8529"

    connection.ip.should == "http://localhost"
    connection.port.should == 8529
  end

  it "should default to localhost and ArangoDB port" do
    connection = subject.new
    connection.ip.should == "http://localhost"
    connection.port.should == 8529
  end

  describe "initialized connection" do
    subject { Ashikawa::Core::Connection.new "http://localhost:8529" }

    it "should send a get request" do
      stub_request(:get, "http://localhost:8529/_api/my/path").to_return body: '{ "name": "dude" }'

      subject.send_request "/my/path"

      WebMock.should have_requested(:get, "http://localhost:8529/_api/my/path")
    end

    it "should send a post request" do
      stub_request(:post, "http://localhost:8529/_api/my/path").with(:body => '{"name":"new_collection"}').to_return body: '{ "name": "dude" }'

      subject.send_request "/my/path", post: { :name => 'new_collection' }

      WebMock.should have_requested(:post, "http://localhost:8529/_api/my/path").with :body => '{"name":"new_collection"}'
    end

    it "should send a put request" do
      stub_request(:put, "http://localhost:8529/_api/my/path").with(:body => '{"name":"new_collection"}').to_return body: '{ "name": "dude" }'

      subject.send_request "/my/path", put: { :name => 'new_collection' }

      WebMock.should have_requested(:put, "http://localhost:8529/_api/my/path").with :body => '{"name":"new_collection"}'
    end

    it "should send a delete request" do
      stub_request(:delete, "http://localhost:8529/_api/my/path").to_return body: '{ "name": "dude" }'

      subject.send_request "/my/path", delete: { }

      WebMock.should have_requested(:delete, "http://localhost:8529/_api/my/path")
    end

    it "should parse JSON" do
      stub_request(:get, "http://localhost:8529/_api/my/path").to_return body: '{ "name": "dude" }'

      subject.send_request("/my/path").should == {"name" => "dude"}
    end
  end
end
