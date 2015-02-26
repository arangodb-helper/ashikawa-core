# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/graph'
require 'ashikawa-core/document'
require 'ashikawa-core/database'
require 'ashikawa-core/exceptions/client_error/vertex_collection_already_present'

describe Ashikawa::Core::Graph do
  let(:database) { instance_double('Ashikawa::Core::Database') }
  let(:raw_graph) { double('RawGraph').as_null_object }
  let(:edge_definition) do
    {
      'collection' => 'friends',
      'from'       => %w(ponies),
      'to'         => %w(dragons ponies)
    }
  end

  def collection_double(name)
    instance_double('Ashikawa::Core::VertexCollection', name: name.to_s)
  end

  def edge_collection_double(name)
    instance_double('Ashikawa::Core::EdgeCollection', name: name.to_s)
  end

  context 'an initialized graph' do
    subject { Ashikawa::Core::Graph.new(database, raw_graph) }

    before do
      allow(raw_graph).to receive(:[]).with('name').and_return('my_graph')
      allow(raw_graph).to receive(:[]).with('_rev').and_return('A113')
      allow(raw_graph).to receive(:fetch).with('orphanCollections').and_return(['orphan'])
      allow(raw_graph).to receive(:fetch).with('edgeDefinitions').and_return([edge_definition])
    end

    its(:database) { should eq database }
    its(:name) { should eq 'my_graph' }
    its(:revision) { should eq 'A113' }
    its(:edge_definitions) { should eq [edge_definition] }

    it 'should delegate send_request to the database' do
      expect(database).to receive(:send_request).with('gharial/my_graph')

      subject.send_request 'gharial/my_graph'
    end

    it 'should extract the name from the _key if no name was provided' do
      allow(raw_graph).to receive(:[]).with('name').and_return(nil)
      allow(raw_graph).to receive(:[]).with('_key').and_return('my_graph')
      expect(subject.name).to eq 'my_graph'
    end

    context 'finding neighbors' do
      let(:some_document) { instance_double('Ashikawa::Core::Document', key: 'somekey') }
      let(:query)         { double('Query') }
      let(:cursor)        { double('Cursor') }

      before do
        allow(database).to receive(:query).and_return(query)
      end

      it 'should return the cursor for the query' do
        allow(query).to receive(:execute)
          .and_return(cursor)

        expect(subject.neighbors(some_document)).to eq cursor
      end

      it 'should run a neighbors AQL for all edge collections' do
        aql_string = <<-AQL.gsub(/^[ \t]*/, '')
        FOR n IN GRAPH_NEIGHBORS(@graph, { _key:@vertex_key }, {})
          RETURN n.vertex
        AQL
        bind_vars = { graph: 'my_graph', vertex_key: 'somekey' }

        expect(query).to receive(:execute)
          .with(aql_string, bind_vars: bind_vars)

        subject.neighbors(some_document)
      end

      it 'should run a neighbors AQL for a specific edge collection' do
        aql_string = <<-AQL.gsub(/^[ \t]*/, '')
        FOR n IN GRAPH_NEIGHBORS(@graph, { _key:@vertex_key }, {edgeCollectionRestriction: @edge_collection})
          RETURN n.vertex
        AQL
        bind_vars = { edge_collection: ['my-edges'], graph: 'my_graph', vertex_key: 'somekey' }

        expect(query).to receive(:execute)
          .with(aql_string, bind_vars: bind_vars)

        subject.neighbors(some_document, edges: ['my-edges'])
      end
    end

    context 'delete the graph' do
      it 'should delete just the graph' do
        expect(database).to receive(:send_request).with('gharial/my_graph', delete: { dropCollections: false })

        subject.delete
      end

      it 'should delete the graph including all collections' do
        expect(database).to receive(:send_request).with('gharial/my_graph', delete: { dropCollections: true })

        subject.delete(drop_collections: true)
      end
    end

    context 'vertex collections' do
      let(:raw_vertex_collection) { double('RawVertexCollection') }

      its(:vertex_collection_names) { should match_array %w(ponies dragons orphan) }

      it 'should have a list of vertex collections' do
        expected_vertex_collection = [
          collection_double(:ponies),
          collection_double(:orphan),
          collection_double(:dragons)
        ]
        allow(subject).to receive(:vertex_collection).and_return(*expected_vertex_collection)

        expect(subject.vertex_collections).to match_array expected_vertex_collection
      end

      it 'should know if a collection has already been added to the list of vertices' do
        allow(subject).to receive(:vertex_collection_names).and_return(['ponies'])

        expect(subject.has_vertex_collection?('dragons')).to be_falsy
        expect(subject.has_vertex_collection?('ponies')).to be_truthy
      end

      context 'fetching a single collection' do
        let(:existing_vertex_collection) { instance_double('Ashikawa::Core::VertexCollection') }

        before do
          allow(database).to receive(:send_request)
            .with('collection/places')
            .and_return(raw_vertex_collection)

          allow(Ashikawa::Core::VertexCollection).to receive(:new)
            .with(database, raw_vertex_collection, subject)
            .and_return(existing_vertex_collection)
        end

        it 'should get a single vertex collection' do
          places_collection = subject.vertex_collection 'places'
          expect(places_collection).to eq existing_vertex_collection
        end
      end

      context 'adding a collection' do
        let(:updated_raw_graph) { double('UpdatedRawGraph') }
        let(:new_vertex_collection) { instance_double('Ashikawa::Core::VertexCollection') }

        before do
          allow(updated_raw_graph).to receive(:[]).with('name').and_return('my_graph')
          allow(updated_raw_graph).to receive(:[]).with('_rev')
          allow(updated_raw_graph).to receive(:fetch).with('orphanCollections').and_return(['books'])
          allow(updated_raw_graph).to receive(:fetch).with('edgeDefinitions').and_return([edge_definition])

          allow(database).to receive(:send_request)
            .with('gharial/my_graph/vertex', post: { collection: 'books' })
            .and_return({ 'graph' => updated_raw_graph })

          allow(database).to receive(:send_request)
            .with('collection/books')
            .and_return(raw_vertex_collection)

          allow(Ashikawa::Core::VertexCollection).to receive(:new)
            .with(database, raw_vertex_collection, subject)
            .and_return(new_vertex_collection)
        end

        it 'should add the new collection to the vertex collections of the graph' do
          books_collection = collection_double(:books)
          allow(subject).to receive(:vertex_collection).and_return(books_collection)

          subject.add_vertex_collection 'books'

          expect(subject.vertex_collections).to include books_collection
        end

        it 'should return the newly created collection' do
          expect(subject.add_vertex_collection('books')).to eq new_vertex_collection
        end

        context 'with an already present collection' do
          before do
            allow(database).to receive(:send_request)
                                .with('gharial/my_graph/vertex', post: { collection: 'books' })
                                .and_raise(Ashikawa::Core::VertexCollectionAlreadyPresent)
          end

          it 'should just return the vertex collection' do
            expect(subject.add_vertex_collection('books')).to eq new_vertex_collection
          end

          it 'should re-raise the exception when called with a bang!' do
            expect { subject.add_vertex_collection!('books') }.to raise_error(Ashikawa::Core::VertexCollectionAlreadyPresent)
          end
        end
      end
    end

    context 'edge collections' do
      let(:raw_edge_collection) { double('RawEdgeCollection') }

      its(:edge_collection_names) { should match_array %w(friends) }

      it 'should have a list of edge collections' do
        expected_edge_collections = [edge_collection_double(:friends)]
        allow(subject).to receive(:edge_collection).and_return(*expected_edge_collections)

        expect(subject.edge_collections).to match_array expected_edge_collections
      end

      context 'fetching a single edge collections' do
        let(:existing_edge_collection) { instance_double('Ashikawa::Core::EdgeCollection') }

        before do
          allow(database).to receive(:send_request)
            .with('collection/friends')
            .and_return(raw_edge_collection)

          allow(Ashikawa::Core::EdgeCollection).to receive(:new)
            .with(database, raw_edge_collection, subject)
            .and_return(existing_edge_collection)
        end

        it 'should return a single edge collection' do
          friends_colection = subject.edge_collection :friends
          expect(friends_colection).to eq existing_edge_collection
        end
      end

      context 'adding a definition' do
        let(:updated_raw_graph) { double('UpdatedRawGraph') }
        let(:new_edge_collection) { instance_double('Ashikawa::Core::EdgeCollection') }
        let(:new_edge_definition) do
          {
            'collection' => 'authorship',
            'from'       => ['author'],
            'to'         => ['books']
          }
        end

        before do
          allow(updated_raw_graph).to receive(:[]).with('name').and_return('my_graph')
          allow(updated_raw_graph).to receive(:[]).with('_rev')
          allow(updated_raw_graph).to receive(:fetch).with('orphanCollections').and_return(['orphans'])
          allow(updated_raw_graph).to receive(:fetch).with('edgeDefinitions').and_return([edge_definition])

          allow(database).to receive(:send_request)
            .with('gharial/my_graph/edge', post: { collection: :authorship, from: [:author], to: [:books] })
            .and_return({ 'graph' => updated_raw_graph })

          allow(subject).to receive(:edge_collection).and_return(new_edge_collection)
        end

        it 'should define the name and direction' do
          expect(database).to receive(:send_request)
            .with('gharial/my_graph/edge', post: { collection: :authorship, from: [:author], to: [:books] })
            .and_return({ 'graph' => updated_raw_graph })

          subject.add_edge_definition(:authorship, from: [:author], to: [:books])
        end

        it 'should add the definition to the collection edge collections' do
          allow(updated_raw_graph).to receive(:fetch).with('edgeDefinitions').and_return([
            edge_definition,
            new_edge_definition
          ])

          subject.add_edge_definition(:authorship, from: [:author], to: [:books])

          expect(subject.edge_collections).to include new_edge_collection
        end

        it 'should return the edge collection' do
          expect(subject.add_edge_definition(:authorship, from: [:author], to: [:books])).to eq new_edge_collection
        end
      end
    end
  end
end
