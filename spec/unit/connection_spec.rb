# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/connection'

describe Ashikawa::Core::Connection do
  let(:request_stub) { Faraday::Adapter::Test::Stubs.new }
  let(:response_headers) { { 'content-type' => 'application/json; charset=utf-8' } }
  subject { Ashikawa::Core::Connection.new(ARANGO_HOST, adapter: [:test, request_stub]) }

  its(:scheme) { should eq('http') }
  its(:host) { should eq('localhost') }
  its(:port) { should eq(8529) }

  it 'should send a get request' do
    request_stub.get('/_api/my/path') do
      [200, response_headers, JSON.generate({ 'name' => 'dude' })]
    end

    subject.send_request 'my/path'

    request_stub.verify_stubbed_calls
  end

  it 'should send a post request' do
    request_stub.post('/_api/my/path') do |request|
      expect(request[:body]).to eq("{\"name\":\"new_collection\"}")
      [200, response_headers, JSON.generate({ 'name' => 'dude' })]
    end

    subject.send_request 'my/path', post: { name: 'new_collection' }
    request_stub.verify_stubbed_calls
  end

  it 'should send a put request' do
    request_stub.put('/_api/my/path') do |request|
      expect(request[:body]).to eq('{"name":"new_collection"}')
      [200, response_headers, JSON.generate({ 'name' => 'dude' })]
    end

    subject.send_request 'my/path', put: { name: 'new_collection' }
    request_stub.verify_stubbed_calls
  end

  it 'should send a delete request' do
    request_stub.delete('/_api/my/path') do |request|
      [200, response_headers, JSON.generate({ 'name' => 'dude' })]
    end

    subject.send_request 'my/path', delete: { }
    request_stub.verify_stubbed_calls
  end

  it 'should write JSON request' do
    request_stub.post('/_api/my/path') do |req|
      expect(req[:body]).to eq('{"test":1}')
      [200, response_headers, JSON.generate({ 'name' => 'dude' })]
    end

    subject.send_request('my/path', post: { 'test' => 1 })
    request_stub.verify_stubbed_calls
  end

  it 'should parse JSON response' do
    request_stub.get('/_api/my/path') do
      [200, response_headers, '{"name":"dude"}']
    end

    expect(subject.send_request('my/path')).to eq({ 'name' => 'dude' })
    request_stub.verify_stubbed_calls
  end

  describe 'authentication' do
    it 'should have authentication turned off by default' do
      expect(subject.authentication?).to be_false
    end

    it 'should tell if authentication is enabled' do
      subject.authenticate_with(username: 'testuser', password: 'testpassword')
      expect(subject.authentication?).to be_true
    end

    it 'should only accept username & password pairs' do
      expect do
        subject.authenticate_with(username: 'kitty')
      end.to raise_error(ArgumentError)

      expect do
        subject.authenticate_with(password: 'cheezburger?')
      end.to raise_error(ArgumentError)
    end

    it 'should allow chaining' do
      expect(subject.authenticate_with(username: 'a', password: 'b')).to eq(subject)
    end

    it 'should send the authentication data with every GET request' do
      pending 'Find out how to check for basic auth via Faraday Stubs'

      request_stub.get('/_api/my/path') do |request|
        [200, response_headers, JSON.generate({ 'name' => 'dude' })]
      end

      subject.authenticate_with username: 'user', password: 'pass'
      subject.send_request 'my/path'

      request_stub.verify_stubbed_calls
    end
  end

  describe 'exception handling' do
    let(:error_message) { 'cannot write file' }
    let(:error_num) { 15 }

    it "should throw a general client error for I'm a teapot" do
      request_stub.get('/_api/bad/request') do
        [
          418,
          response_headers,
          JSON.generate({ 'error' => true, 'errorNum' => error_num, 'errorMessage' => error_message })
        ]
      end

      expect do
        subject.send_request('bad/request')
      end.to raise_error(Ashikawa::Core::ClientError, "#{error_num}: #{error_message}")

      request_stub.verify_stubbed_calls
    end

    it 'should throw its own exception when doing a bad request' do
      request_stub.get('/_api/bad/request') do
        [400, response_headers, '']
      end

      expect do
        subject.send_request('bad/request')
      end.to raise_error(Ashikawa::Core::BadSyntax)

      request_stub.verify_stubbed_calls
    end

    it 'should throw a general server error for the generic server error' do
      request_stub.get('/_api/bad/request') do
        [
          500,
          response_headers,
          JSON.generate({ 'error' => true, 'errorNum' => error_num, 'errorMessage' => error_message })
        ]
      end

      expect do
        subject.send_request('bad/request')
      end.to raise_error(Ashikawa::Core::ServerError, "#{error_num}: #{error_message}")

      request_stub.verify_stubbed_calls
    end

    it 'should raise an exception if a document is not found' do
      request_stub.get('/_api/document/4590/333') do
        [404, response_headers, '']
      end

      expect { subject.send_request 'document/4590/333' }.to raise_error(Ashikawa::Core::DocumentNotFoundException)

      request_stub.verify_stubbed_calls
    end

    it 'should raise an exception if a collection is not found' do
      request_stub.get('/_api/collection/4590') do
        [404, response_headers, '']
      end

      expect { subject.send_request 'collection/4590' }.to raise_error(Ashikawa::Core::CollectionNotFoundException)

      request_stub.verify_stubbed_calls
    end

    it 'should raise an exception if an index is not found' do
      request_stub.get('/_api/index/4590/333') do
        [404, response_headers, '']
      end

      expect { subject.send_request 'index/4590/333' }.to raise_error(Ashikawa::Core::IndexNotFoundException)

      request_stub.verify_stubbed_calls
    end

    it 'should raise an exception for unknown pathes' do
      request_stub.get('/_api/unknown_path/4590/333') do
        [404, response_headers, '']
      end

      expect { subject.send_request 'unknown_path/4590/333' }.to raise_error(Ashikawa::Core::ResourceNotFound)

      request_stub.verify_stubbed_calls
    end

    it 'should raise an error if a malformed JSON was returned from the server' do
      request_stub.get('/_api/document/4590/333') do
        [200, response_headers, '{"a":1']
      end

      expect { subject.send_request 'document/4590/333' }.to raise_error(Ashikawa::Core::JsonError)

      request_stub.verify_stubbed_calls
    end

    it 'should raise an error if the content type of the response is not JSON' do
      request_stub.get('/_api/document/4590/333') do
        [200, { 'content-type' => 'text/html; charset=utf-8' }, '']
      end

      expect { subject.send_request 'document/4590/333' }.to raise_error(Ashikawa::Core::JsonError)

      request_stub.verify_stubbed_calls
    end
  end

  describe 'logging' do
    let(:request_stub) { Faraday::Adapter::Test::Stubs.new }
    let(:logger) { double }
    subject do
      Ashikawa::Core::Connection.new(ARANGO_HOST, adapter: [:test, request_stub], logger: logger)
    end

    it 'should log a get request' do
      request_stub.get('/_api/test') do
        [200, response_headers, JSON.generate({ a: 1 })]
      end
      expect(logger).to receive(:info).with("GET #{ARANGO_HOST}/_api/test ")
      expect(logger).to receive(:info).with('200 {"a":1}')

      subject.send_request('test')
    end

    it 'should log a post request' do
      request_stub.post('/_api/test') do
        [201, response_headers, JSON.generate({ b: 2 })]
      end
      expect(logger).to receive(:info).with("POST #{ARANGO_HOST}/_api/test {:a=>2}")
      expect(logger).to receive(:info).with('201 {"b":2}')

      subject.send_request('test', post: { a: 2 })
    end
  end
end
