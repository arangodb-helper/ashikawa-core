# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/query'

describe Ashikawa::Core::Query do
  let(:collection) { double }
  let(:database) { double }

  describe 'initialized with collection' do
    subject { Ashikawa::Core::Query.new(collection) }
    let(:name) { double }

    before do
      allow(collection).to receive(:name).and_return(name)
      allow(collection).to receive(:database).and_return(double)
    end

    describe 'get all' do
      let(:limit) { double }
      let(:skip) { double }

      it 'should list all documents' do
        expect(collection).to receive(:send_request)
          .with('simple/all', put: { 'collection' => name })
          .and_return { server_response('simple-queries/all') }
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.all
      end

      it 'should be able to limit the number of documents' do
        expect(collection).to receive(:send_request)
          .with('simple/all', put: { 'collection' => name, 'limit' => limit })
          .and_return { server_response('simple-queries/all_skip') }
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.all(limit: limit)
      end

      it 'should be able to skip documents' do
        expect(collection).to receive(:send_request)
          .with('simple/all', put: { 'collection' => name, 'skip' => skip })
          .and_return { server_response('simple-queries/all_limit') }
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.all(skip: skip)
      end
    end

    describe 'first by example' do
      let(:example) { double }
      let(:response) { server_response('simple-queries/example') }

      it 'should find exactly one fitting document' do
        allow(collection).to receive(:database)
          .and_return(double)
        expect(collection).to receive(:send_request)
          .with('simple/first-example', put: { 'collection' => name, 'example' => example })
          .and_return(response)
        expect(Ashikawa::Core::Document).to receive(:new)

        subject.first_example(example)
      end
    end

    describe 'all by example' do
      let(:example) { { hello: 'world' } }
      let(:response) { server_response('simple-queries/example') }
      let(:limit) { double }
      let(:skip) { double }

      it 'should find all fitting documents' do
        expect(collection).to receive(:send_request)
          .with('simple/by-example', put: { 'collection' => name, 'example' => example })
          .and_return(response)
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.by_example(example)
      end

      it 'should be able to limit the number of documents' do
        expect(collection).to receive(:send_request)
          .with('simple/by-example', put: { 'collection' => name, 'limit' => limit, 'example' => example })
          .and_return(response)
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.by_example(example, limit: limit)
      end

      it 'should be able to skip documents' do
        expect(collection).to receive(:send_request)
          .with('simple/by-example', put: { 'collection' => name, 'skip' => skip, 'example' => example })
          .and_return(response)
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.by_example(example, skip: skip)
      end
    end

    describe 'near a geolocation' do
      let(:latitude) { double }
      let(:longitude) { double }
      let(:arguments) do
        {
          'collection' => name,
          'latitude' => latitude,
          'longitude' => longitude
        }
      end
      let(:response) { server_response('simple-queries/near') }

      it 'should find documents based on latitude/longitude' do
        expect(collection).to receive(:send_request)
          .with('simple/near', put: arguments)
          .and_return { response }
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.near(latitude: latitude, longitude: longitude)
      end
    end

    describe 'within a radius of a geolocation' do
      let(:latitude) { double }
      let(:longitude) { double }
      let(:radius) { double }
      let(:arguments) do
        {
          'collection' => name,
          'latitude' => latitude,
          'longitude' => longitude,
          'radius' => radius
        }
      end
      let(:response) { server_response('simple-queries/within') }

      it 'should look for documents based on latidude/longitude' do
        expect(collection).to receive(:send_request)
          .with('simple/within' , put: arguments)
          .and_return { response }
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.within(latitude: latitude, longitude: longitude, radius: radius)
      end
    end

    describe 'in a certain range' do
      let(:attribute) { double }
      let(:left) { double }
      let(:right) { double }
      let(:closed) { double }
      let(:arguments) do
        {
          'collection' => name,
          'attribute' => attribute,
          'left' => left,
          'right' => right,
          'closed' => closed
        }
      end
      let(:response) { server_response('simple-queries/range') }

      it 'should look for documents with an attribute in that range' do
        expect(collection).to receive(:send_request)
          .with('simple/range' , put: arguments)
          .and_return { response }
        expect(Ashikawa::Core::Cursor).to receive(:new)

        subject.in_range(attribute: attribute, left: left, right: right, closed: closed)
      end
    end

    describe 'with an AQL query' do
      let(:query) { double }
      let(:count) { double }
      let(:batch_size) { double }
      let(:arguments) do
        {
          'query' => query,
          'count' => count,
          'batchSize' => batch_size
        }
      end
      let(:response) { server_response('cursor/query') }

      it 'should be able to execute it' do
        allow(collection).to receive(:database)
          .and_return(double)
        expect(collection).to receive(:send_request)
          .with('cursor', post: arguments)
          .and_return(response)
        expect(Ashikawa::Core::Cursor).to receive(:new)
          .with(collection.database, response)

        subject.execute(query, count: count, batch_size: batch_size)
      end

      it 'should return true when asked if a valid query is valid' do
        expect(collection).to receive(:send_request)
          .with('query', post: { 'query' => query })
          .and_return { server_response('query/valid') }

        expect(subject.valid?(query)).to be_true
      end

      it 'should return false when asked if an invalid query is valid' do
        allow(collection).to receive(:send_request)
          .and_raise(Ashikawa::Core::BadSyntax)
        expect(collection).to receive(:send_request)
          .with('query', post: { 'query' => query })

        expect(subject.valid?(query)).to be_false
      end
    end
  end

  describe 'initialized with database' do
    subject { Ashikawa::Core::Query.new(database) }

    it 'should throw an exception when a simple query is executed' do
      [:all, :by_example, :first_example, :near, :within, :in_range].each do |method|
        expect { subject.send method }.to raise_error(Ashikawa::Core::NoCollectionProvidedException)
      end
    end

    describe 'with an AQL query' do
      let(:query) { double }
      let(:count) { double }
      let(:batch_size) { double }
      let(:arguments) do
        {
          'query' => query,
          'count' => count,
          'batchSize' => batch_size
        }
      end
      let(:query_response) { server_response('cursor/query') }
      let(:valid_response) { server_response('cursor/query') }

      it 'should be able to execute it' do
        expect(database).to receive(:send_request)
          .with('cursor', post: arguments)
          .and_return(query_response)
        expect(Ashikawa::Core::Cursor).to receive(:new)
          .with(database, query_response)

        subject.execute(query, count: count, batch_size: batch_size)
      end

      it 'should return true when asked if a valid query is valid' do
        expect(database).to receive(:send_request)
          .with('query', post: { 'query' => query })
          .and_return { valid_response }

        expect(subject.valid?(query)).to be_true
      end

      it 'should return false when asked if an invalid query is valid' do
        expect(database).to receive(:send_request)
          .with('query', post: { 'query' => query })
          .and_raise(Ashikawa::Core::BadSyntax)

        expect(subject.valid?(query)).to be_false
      end
    end
  end
end
