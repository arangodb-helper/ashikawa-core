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

    subject.send_request 'my/path', delete: {}
    request_stub.verify_stubbed_calls
  end

  describe 'authentication' do
    it 'should have authentication turned off by default' do
      expect(subject.authentication?).to be_false
    end

    it 'should tell if authentication is enabled' do
      subject.authenticate_with('testuser', 'testpassword')
      expect(subject.authentication?).to be_true
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

    it 'should throw its own exception when doing a bad request' do
      request_stub.get('/_api/secret') do
        [401, response_headers, '']
      end

      expect do
        subject.send_request('secret')
      end.to raise_error(Ashikawa::Core::AuthenticationFailed)

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
  end

  describe 'initializing Faraday' do
    subject { Ashikawa::Core::Connection }
    let(:adapter) { double('Adapter') }
    let(:logger) { double('Logger') }
    let(:blocky) { double('Block') }

    it 'should initalize with specific logger and adapter' do
      expect(Faraday).to receive(:new).with("#{ARANGO_HOST}/_api").and_yield(blocky)
      expect(blocky).to receive(:request).with(:json)
      expect(blocky).to receive(:response).with(:logger, logger)
      expect(blocky).to receive(:response).with(:error_response)
      expect(blocky).to receive(:response).with(:json)
      expect(blocky).to receive(:adapter).with(adapter)

      subject.new(ARANGO_HOST, adapter: adapter, logger: logger)
    end

    it 'should initialize with defaults when no specific logger and adapter was given' do
      expect(Faraday).to receive(:new).with("#{ARANGO_HOST}/_api").and_yield(blocky)
      expect(blocky).to receive(:request).with(:json)
      expect(blocky).to receive(:response).with(:logger, NullLogger.instance)
      expect(blocky).to receive(:response).with(:error_response)
      expect(blocky).to receive(:response).with(:json)
      expect(blocky).to receive(:adapter).with(Faraday.default_adapter)

      subject.new(ARANGO_HOST)
    end
  end
end
