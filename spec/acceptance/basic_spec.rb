# -*- encoding : utf-8 -*-
require 'acceptance/spec_helper'

describe 'Basics' do
  describe 'for an initialized database' do
    subject { DATABASE }

    after :each do
      subject.collections.each { |collection| collection.delete }
    end

    it 'should do what the README describes' do
      subject['my_collection']
      subject['my_collection'].name = 'new_name'
      subject['new_name'].delete
    end

    it 'should create and delete collections' do
      subject.collections.each { |collection| collection.delete }
      subject['collection_1']
      subject['collection_2']
      subject['collection_3']
      expect(subject.collections.length).to eq(3)
      subject['collection_3'].delete
      expect(subject.collections.length).to eq(2)
    end

    it 'should create a non-volatile collection by default' do
      subject.create_collection('nonvolatile_collection')
      expect(subject['nonvolatile_collection'].volatile?).to be_false
    end

    it 'should create a volatile collection' do
      subject.create_collection('volatile_collection', is_volatile: true)
      expect(subject['volatile_collection'].volatile?).to be_true
    end

    it 'should create an autoincrementing collection' do
      subject.create_collection('autoincrement_collection', is_volatile: true, key_options: {
        type: :autoincrement,
        increment: 10,
        allow_user_keys: false
      })
      key_options = subject['autoincrement_collection'].key_options

      expect(key_options.type).to eq('autoincrement')
      expect(key_options.offset).to eq(0)
      expect(key_options.increment).to eq(10)
      expect(key_options.allow_user_keys).to eq(false)
    end

    it 'should be possible to create an edge collection' do
      subject.create_collection('edge_collection', content_type: :edge)
      expect(subject['edge_collection'].content_type).to eq(:edge)
    end

    it 'should be possible to change the name of a collection' do
      my_collection = subject['test_collection']
      expect(my_collection.name).to eq('test_collection')
      my_collection.name = 'my_new_name'
      expect(my_collection.name).to eq('my_new_name')
    end

    it 'should be possible to find a collection by ID' do
      my_collection = subject['test_collection']
      expect(subject[my_collection.id].name).to eq('test_collection')
    end

    it 'should be possible to list all system collections' do
      expect(subject.system_collections.length).to be > 0
    end

    it 'should be possible to load and unload collections' do
      my_collection = subject['test_collection']
      expect(my_collection.status.loaded?).to be_true
      my_collection.unload
      my_id = my_collection.id
      subject[my_id]
      expect(subject[my_id].status.loaded?).to be_false
    end

    it 'should be possible to get figures' do
      my_collection = subject['test_collection']
      expect(my_collection.figure.alive_size.class).to eq(Fixnum)
      expect(my_collection.figure.alive_count.class).to eq(Fixnum)
      expect(my_collection.figure.dead_size.class).to eq(Fixnum)
      expect(my_collection.figure.dead_count.class).to eq(Fixnum)
      expect(my_collection.figure.dead_deletion.class).to eq(Fixnum)
      expect(my_collection.figure.datafiles_count.class).to eq(Fixnum)
      expect(my_collection.figure.datafiles_file_size.class).to eq(Fixnum)
      expect(my_collection.figure.journals_count.class).to eq(Fixnum)
      expect(my_collection.figure.journals_file_size.class).to eq(Fixnum)
      expect(my_collection.figure.shapes_count.class).to eq(Fixnum)
    end

    it 'should change and receive information about waiting for sync' do
      my_collection = subject['my_collection']
      my_collection.wait_for_sync = false
      expect(my_collection.wait_for_sync?).to be_false
      my_collection.wait_for_sync = true
      expect(my_collection.wait_for_sync?).to be_true
    end

    it 'should be possible to get information about the number of documents' do
      empty_collection = subject['empty_collection']
      expect(empty_collection.length).to eq(0)
      empty_collection.create_document(name: 'testname', age: 27)
      empty_collection.create_document(name: 'anderer name', age: 28)
      expect(empty_collection.length).to eq(2)
      empty_collection.truncate!
      expect(empty_collection.length).to eq(0)
    end

    it 'should be possible to update the attributes of a document' do
      collection = subject['documenttests']

      document = collection.create_document(name: 'The Dude', bowling: true)
      document_key = document.key
      document['name'] = 'Other Dude'
      document.save

      expect(collection.fetch(document_key)['name']).to eq('Other Dude')
    end

    it 'should be possible to access and create documents from a collection' do
      collection = subject['documenttests']

      document = collection.create_document(name: 'The Dude', bowling: true)
      document_key = document.key
      expect(collection.fetch(document_key)['name']).to eq('The Dude')

      collection.replace(document_key, { name: 'Other Dude', bowling: true })
      expect(collection.fetch(document_key)['name']).to eq('Other Dude')
    end

    it 'should be possible to create an edge between two documents' do
      nodes = subject.create_collection('nodecollection')
      edges = subject.create_collection('edgecollection', content_type: :edge)

      a = nodes.create_document(name: 'a')
      b = nodes.create_document(name: 'b')
      e = edges.create_edge(a, b, { name: 'fance_edge' })

      e = edges.fetch(e.key)
      expect(e.from_id).to eq(a.id)
      expect(e.to_id).to eq(b.id)
    end

    it 'should be possible to get a document by either its key or its ID' do
      collection = subject['documenttests']
      document = collection.create_document(name: 'The Dude')

      expect(collection.fetch(document.key)).to eq collection.fetch(document.id)
    end

    it 'should be possible to get a single attribute by AQL query' do
      collection = subject['documenttests']
      collection.truncate!
      collection.create_document(name: 'The Dude', bowling: true)

      expect(subject.query.execute('FOR doc IN documenttests RETURN doc.name').to_a.first). to eq 'The Dude'
    end
  end

  describe 'for a created document' do
    let(:database) { DATABASE }
    let(:collection) { database['documenttests'] }
    subject { collection.create_document(name: 'The Dude') }
    let(:document_key) { subject.key }

    it 'should be possible to manipulate documents and save them' do
      subject['name'] = 'Jeffrey Lebowski'
      expect(subject['name']).to eq('Jeffrey Lebowski')
      expect(collection.fetch(document_key)['name']).to eq('The Dude')
      subject.save
      expect(collection.fetch(document_key)['name']).to eq('Jeffrey Lebowski')
    end

    it 'should be possible to delete a document' do
      collection.fetch(document_key).delete
      expect { collection.fetch(document_key) }.to raise_exception Ashikawa::Core::DocumentNotFoundException
    end

    it "should not be possible to delete a document that doesn't exist" do
      expect { collection.fetch(123).delete }.to raise_exception Ashikawa::Core::DocumentNotFoundException
    end

    it 'should be possible to refresh a document' do
      changed_document = collection.fetch(document_key)
      changed_document['name'] = 'New Name'
      changed_document.save

      expect(subject['name']).to eq('The Dude')
      subject.refresh!
      expect(subject['name']).to eq('New Name')
    end
  end
end
