# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/database'

describe Ashikawa::Core::Database do
  subject { Ashikawa::Core::Database }

  let(:url) { double }
  let(:host) { double }
  let(:port) { double }
  let(:scheme) { double }
  let(:connection) { double('connection', host: host, port: port, scheme: scheme) }
  let(:js_function) { double }
  let(:collections) { double }
  let(:transaction) { double }
  let(:logger) { double }
  let(:adapter) { double }
  let(:configuration) { double }

  it 'should initialize with a configuration object' do
    expect(Ashikawa::Core::Configuration).to receive(:new)
      .and_return(configuration)
    expect(configuration).to receive(:connection)
    expect { |b| Ashikawa::Core::Database.new(&b) }.to yield_with_args(configuration)
  end

  describe 'initialized database' do
    subject do
      Ashikawa::Core::Database.new do |config|
        config.connection = connection
      end
    end

    it 'should create a query' do
      expect(Ashikawa::Core::Query).to receive(:new)
        .exactly(1).times
        .with(subject)

      subject.query
    end

    it 'should fetch all available non-system collections' do
      expect(connection).to receive(:send_request)
        .with('collection')
        .and_return { server_response('collections/all') }

      (0..1).each do |k|
        expect(Ashikawa::Core::Collection).to receive(:new)
          .with(subject, server_response('collections/all')['collections'][k])
      end

      expect(subject.collections.length).to eq(2)
    end

    it 'should fetch all available non-system collections' do
      expect(connection).to receive(:send_request)
        .with('collection')
        .and_return { server_response('collections/all') }

      expect(Ashikawa::Core::Collection).to receive(:new)
        .exactly(5).times

      expect(subject.system_collections.length).to eq(5)
    end

    it 'should create a non volatile collection by default' do
      expect(connection).to receive(:send_request)
        .with('collection', post: { name: 'volatile_collection' })
        .and_return { server_response('collections/60768679') }

      expect(Ashikawa::Core::Collection).to receive(:new)
        .with(subject, server_response('collections/60768679'))

      subject.create_collection('volatile_collection')
    end

    it 'should create a volatile collection when asked' do
      expect(connection).to receive(:send_request)
        .with('collection', post: { name: 'volatile_collection', isVolatile: true })
        .and_return { |path| server_response('collections/60768679') }

      expect(Ashikawa::Core::Collection).to receive(:new)
        .with(subject, server_response('collections/60768679'))

      subject.create_collection('volatile_collection', is_volatile: true)
    end

    it 'should create an autoincrement collection when asked' do
      expect(connection).to receive(:send_request).with('collection',
                                                        post: {
          name: 'autoincrement_collection', keyOptions: {
            type: 'autoincrement',
            offset: 0,
            increment: 10,
            allowUserKeys: false
          }
        }
      )

      expect(Ashikawa::Core::Collection).to receive(:new)

      subject.create_collection('autoincrement_collection', key_options: {
        type: :autoincrement,
        offset: 0,
        increment: 10,
        allow_user_keys: false
      })
    end

    it 'should create an edge collection when asked' do
      expect(connection).to receive(:send_request)
        .with('collection', post: { name: 'volatile_collection', type: 3 })
        .and_return { |path| server_response('collections/60768679') }

      expect(Ashikawa::Core::Collection).to receive(:new)
        .with(subject, server_response('collections/60768679'))

      subject.create_collection('volatile_collection', content_type: :edge)
    end

    it 'should fetch a single collection if it exists' do
      expect(connection).to receive(:send_request)
        .with('collection/60768679')
        .and_return { |path| server_response('collections/60768679') }

      expect(Ashikawa::Core::Collection).to receive(:new)
        .with(subject, server_response('collections/60768679'))

      subject.collection(60_768_679)
    end

    it 'should fetch a single collection with the array syntax' do
      expect(connection).to receive(:send_request)
        .with('collection/60768679')
        .and_return { |path| server_response('collections/60768679') }

      expect(Ashikawa::Core::Collection).to receive(:new)
        .with(subject, server_response('collections/60768679'))

      subject[60_768_679]
    end

    it "should create a single collection if it doesn't exist" do
      allow(connection).to receive :send_request do |path, method|
        method ||= {}
        if method.key? :post
          server_response('collections/60768679')
        else
          raise Ashikawa::Core::CollectionNotFoundException
        end
      end
      expect(connection).to receive(:send_request).with('collection/new_collection')
      expect(connection).to receive(:send_request).with('collection', post: { name: 'new_collection' })
      expect(Ashikawa::Core::Collection).to receive(:new).with(subject, server_response('collections/60768679'))

      subject['new_collection']
    end

    it 'should send a request via the connection object' do
      expect(connection).to receive(:send_request)
        .with('my/path', post: { data: 'mydata' })

      subject.send_request 'my/path', post: { data: 'mydata' }
    end

    it 'should create a transaction' do
      expect(Ashikawa::Core::Transaction).to receive(:new)
        .with(subject, js_function, collections)
        .and_return(transaction)

      expect(subject.create_transaction(js_function, collections)).to be(transaction)
    end
  end
end
