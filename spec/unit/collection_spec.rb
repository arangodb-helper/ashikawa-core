# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/collection'

describe Ashikawa::Core::Collection do
  let(:database) { double }
  let(:raw_document_collection) do
    {
      'id' => '60768679',
      'name' => 'example_1',
      'status' => 3,
      'type' => 2,
      'error' => false,
      'code' => 200
    }
  end
  let(:raw_edge_collection) do
    {
      'id' => '60768679',
      'name' => 'example_1',
      'type' => 3
    }
  end

  describe 'an initialized collection' do
    subject { Ashikawa::Core::Collection.new(database, raw_document_collection) }

    let(:raw_key_options) { double }
    let(:key_options) { double }
    let(:response) { double }
    let(:value) { double }
    let(:figure) { double }

    its(:name) { should eq('example_1') }
    its(:id) { should eq('60768679') }

    it 'should know how many documents the collection has' do
      allow(response).to receive(:[])
        .with('count')
        .and_return(value)
      expect(database).to receive(:send_request)
        .with('collection/60768679/count', {})
        .and_return(response)

      expect(subject.length).to be(value)
    end

    it 'should check for the figures' do
      allow(response).to receive(:[])
        .with('figures')
        .and_return(value)
      expect(database).to receive(:send_request)
        .with('collection/60768679/figures', {})
        .and_return(response)

      expect(Ashikawa::Core::Figure).to receive(:new)
        .exactly(1).times
        .with(value)
        .and_return(figure)

      expect(subject.figure).to be(figure)
    end

    it 'should create a query' do
      expect(Ashikawa::Core::Query).to receive(:new)
        .exactly(1).times
        .with(subject)

      subject.query
    end

    it 'should get deleted' do
      expect(database).to receive(:send_request)
        .with('collection/60768679/', delete: {})

      subject.delete
    end

    it 'should get loaded' do
      expect(database).to receive(:send_request)
        .with('collection/60768679/load', put: {})

      subject.load
    end

    it 'should get unloaded' do
      expect(database).to receive(:send_request)
        .with('collection/60768679/unload', put: {})

      subject.unload
    end

    it 'should get truncated' do
      expect(database).to receive(:send_request)
        .with('collection/60768679/truncate', put: {})

      subject.truncate!
    end

    it 'should change its name' do
      expect(database).to receive(:send_request)
        .with('collection/60768679/rename', put: { 'name' => value })

      subject.name = value
    end

    it 'should change if it waits for sync' do
      expect(database).to receive(:send_request)
        .with('collection/60768679/properties', put: { 'waitForSync' => value })

      subject.wait_for_sync = value
    end

    describe 'properties' do
      before do
        expect(database).to receive(:send_request)
          .with('collection/60768679/properties', {})
          .and_return(response)
      end

      it 'should check if the collection waits for sync' do
        allow(response).to receive(:[])
          .with('waitForSync')
          .and_return(value)

        expect(subject.wait_for_sync?).to be(value)
      end

      it 'should know if the collection is volatile' do
        allow(response).to receive(:[])
          .with('isVolatile')
          .and_return(value)

        expect(subject.volatile?).to be(value)
      end

      it 'should check for the key options' do
        allow(response).to receive(:[])
          .with('keyOptions')
          .and_return(value)
        expect(Ashikawa::Core::KeyOptions).to receive(:new)
          .with(value)
          .and_return(key_options)

        expect(subject.key_options).to eq(key_options)
      end
    end

    describe 'non-existing documents' do
      before do
        allow(database).to receive(:send_request)
          .and_raise(Ashikawa::Core::DocumentNotFoundException)
      end

      it 'should throw an exception when using fetch' do
        expect do
          subject.fetch(123)
        end.to raise_exception Ashikawa::Core::DocumentNotFoundException
      end

      it 'should return nil when using []' do
        expect(subject[123]).to be_nil
      end
    end

    describe 'indexes' do
      let(:index_response) { double }

      it 'should add a new index' do
        expect(database).to receive(:send_request)
          .with('index?collection=60768679', post: {
            'type' => 'hash', 'fields' => %w{a b}, 'unique' => false
          })
          .and_return(index_response)
        expect(Ashikawa::Core::Index).to receive(:new)
          .with(subject, index_response)

        subject.add_index(:hash, on: [:a, :b])
      end

      it 'should add a new unique index' do
        expect(database).to receive(:send_request)
          .with('index?collection=60768679', post: {
            'type' => 'hash', 'fields' => %w{a b}, 'unique' => true
          })
          .and_return(index_response)
        expect(Ashikawa::Core::Index).to receive(:new)
          .with(subject, index_response)

        subject.add_index(:hash, on: [:a, :b], unique: true)
      end

      it 'should get an index by ID' do
        allow(database).to receive(:send_request)
          .with('index/example_1/168054969')
          .and_return(index_response)
        expect(Ashikawa::Core::Index).to receive(:new)
          .with(subject, index_response)

        subject.index(168_054_969)
      end

      it 'should get all indexes' do
        multi_index_response = double
        allow(multi_index_response).to receive(:map)
          .and_yield(index_response)

        cursor = double
        allow(cursor).to receive(:[])
          .with('indexes')
          .and_return(multi_index_response)

        allow(database).to receive(:send_request)
          .with('index?collection=60768679')
          .and_return(cursor)

        expect(Ashikawa::Core::Index).to receive(:new)
          .with(subject, index_response)

        subject.indices
      end
    end
  end

  describe 'an initialized document collection' do
    subject { Ashikawa::Core::Collection.new database, raw_document_collection }

    let(:document) { double }
    let(:response) { double }
    let(:raw_document) { double }
    let(:value) { double }

    its(:content_type) { should be(:document) }

    it 'should receive a document by ID via fetch' do
      expect(database).to receive(:send_request)
        .with('document/60768679/333', {})
        .and_return(double)
      expect(Ashikawa::Core::Document).to receive(:new)

      subject.fetch(333)
    end

    it 'should receive a document by ID via []' do
      expect(database).to receive(:send_request)
        .with('document/60768679/333', {})
        .and_return(double)
      expect(Ashikawa::Core::Document).to receive(:new)

      subject[333]
    end

    it 'should replace a document by ID' do
      expect(database).to receive(:send_request)
        .with('document/60768679/333', put: { 'name' => value })

      subject.replace(333, { 'name' => value })
    end

    it 'should create a new document' do
      allow(database).to receive(:send_request)
        .with('document?collection=60768679', post: raw_document)
        .and_return(response)
      expect(Ashikawa::Core::Document).to receive(:new)
        .with(database, response, raw_document)
        .and_return(document)

      subject.create_document(raw_document)
    end

    it 'should not create a new edge' do
      expect do
        subject.create_edge(double, double, { 'quote' => "D'ya have to use s'many cuss words?" })
      end.to raise_exception(RuntimeError, "Can't create an edge in a document collection")
    end
  end

  describe 'an initialized edge collection' do
    subject { Ashikawa::Core::Collection.new database, raw_edge_collection }

    let(:document) { double }
    let(:response) { double }
    let(:raw_document) { double }

    its(:content_type) { should be(:edge) }

    it 'should receive an edge by ID via fetch' do
      expect(database).to receive(:send_request)
        .with('edge/60768679/333', {})
        .and_return(double)
      expect(Ashikawa::Core::Edge).to receive(:new)

      subject.fetch(333)
    end

    it 'should receive an edge by ID via []' do
      expect(database).to receive(:send_request)
        .with('edge/60768679/333', {})
        .and_return(double)
      expect(Ashikawa::Core::Edge).to receive(:new)

      subject[333]
    end

    it 'should replace an edge by ID' do
      expect(database).to receive(:send_request)
        .with('edge/60768679/333', put: { 'name' => 'The Dude' })

      subject.replace(333, { 'name' => 'The Dude' })
    end

    it 'should create a new edge' do
      allow(database).to receive(:send_request)
        .with('edge?collection=60768679&from=1&to=2', post: raw_document)
        .and_return(response)
      expect(Ashikawa::Core::Edge).to receive(:new)
        .with(database, response, raw_document)
        .and_return(document)

      subject.create_edge(double(id: '1'), double(id: '2'), raw_document)
    end

    it 'should not create a new document' do
      expect do
        subject.create_document({ 'quote' => "D'ya have to use s'many cuss words?" })
      end.to raise_exception(RuntimeError, "Can't create a document in an edge collection")
    end
  end
end
