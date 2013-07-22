require 'acceptance/spec_helper'

describe "Basics" do
  describe "for an initialized database" do
    subject {
      Ashikawa::Core::Database.new do |config|
        config.url = ARANGO_HOST
      end
    }

    after :each do
      subject.collections.each { |collection| collection.delete }
    end

    it "should do what the README describes" do
      subject["my_collection"]
      subject["my_collection"].name = "new_name"
      subject["new_name"].delete
    end

    it "should create and delete collections" do
      subject.collections.each { |collection| collection.delete }
      subject["collection_1"]
      subject["collection_2"]
      subject["collection_3"]
      subject.collections.length.should == 3
      subject["collection_3"].delete
      subject.collections.length.should == 2
    end

    it "should create a non-volatile collection by default" do
      subject.create_collection("nonvolatile_collection")
      subject["nonvolatile_collection"].volatile?.should be_false
    end

    it "should create a volatile collection" do
      subject.create_collection("volatile_collection", :is_volatile => true)
      subject["volatile_collection"].volatile?.should be_true
    end

    it "should create an autoincrementing collection" do
      subject.create_collection("autoincrement_collection", :is_volatile => true, :key_options => {
        :type => :autoincrement,
        :increment => 10,
        :allow_user_keys => false
      })
      key_options = subject["autoincrement_collection"].key_options

      key_options.type.should == "autoincrement"
      key_options.offset.should == 0
      key_options.increment.should == 10
      key_options.allow_user_keys.should == false
    end

    it "should be possible to create an edge collection" do
      subject.create_collection("edge_collection", :content_type => :edge)
      subject["edge_collection"].content_type.should == :edge
    end

    it "should be possible to change the name of a collection" do
      my_collection = subject["test_collection"]
      my_collection.name.should == "test_collection"
      my_collection.name = "my_new_name"
      my_collection.name.should == "my_new_name"
    end

    it "should be possible to find a collection by ID" do
      my_collection = subject["test_collection"]
      subject[my_collection.id].name.should == "test_collection"
    end

    it "should be possible to list all system collections" do
      subject.system_collections.length.should > 0
    end

    it "should be possible to load and unload collections" do
      my_collection = subject["test_collection"]
      my_collection.status.loaded?.should be_true
      my_collection.unload
      my_id = my_collection.id
      my_collection = subject[my_id]
      subject[my_id].status.loaded?.should be_false
    end

    it "should be possible to get figures" do
      my_collection = subject["test_collection"]
      my_collection.figure.alive_size.class.should == Fixnum
      my_collection.figure.alive_count.class.should == Fixnum
      my_collection.figure.dead_size.class.should == Fixnum
      my_collection.figure.dead_count.class.should == Fixnum
      my_collection.figure.dead_deletion.class.should == Fixnum
      my_collection.figure.datafiles_count.class.should == Fixnum
      my_collection.figure.datafiles_file_size.class.should == Fixnum
      my_collection.figure.journals_count.class.should == Fixnum
      my_collection.figure.journals_file_size.class.should == Fixnum
      my_collection.figure.shapes_count.class.should == Fixnum
    end

    it "should change and receive information about waiting for sync" do
      my_collection = subject["my_collection"]
      my_collection.wait_for_sync = false
      my_collection.wait_for_sync?.should be_false
      my_collection.wait_for_sync = true
      my_collection.wait_for_sync?.should be_true
    end

    it "should be possible to get information about the number of documents" do
      empty_collection = subject["empty_collection"]
      empty_collection.length.should == 0
      empty_collection.create_document({ :name => "testname", :age => 27})
      empty_collection.create_document({ :name => "anderer name", :age => 28})
      empty_collection.length.should == 2
      empty_collection.truncate!
      empty_collection.length.should == 0
    end

    it "should be possible to update the attributes of a document" do
      collection = subject["documenttests"]

      document = collection.create_document(:name => "The Dude", :bowling => true)
      document_key = document.key
      document["name"] = "Other Dude"
      document.save

      collection.fetch(document_key)["name"].should == "Other Dude"
    end

    it "should be possible to access and create documents from a collection" do
      collection = subject["documenttests"]

      document = collection.create_document(:name => "The Dude", :bowling => true)
      document_key = document.key
      collection.fetch(document_key)["name"].should == "The Dude"

      collection.replace(document_key, { :name => "Other Dude", :bowling => true })
      collection.fetch(document_key)["name"].should == "Other Dude"
    end

    it "should be possible to create an edge between two documents" do
      nodes = subject.create_collection("nodecollection")
      edges = subject.create_collection("edgecollection", :content_type => :edge)

      a = nodes.create_document({:name => "a"})
      b = nodes.create_document({:name => "b"})
      e = edges.create_edge(a, b, {:name => "fance_edge"})

      e = edges.fetch(e.key)
      e.from_id.should == a.id
      e.to_id.should == b.id
    end
  end

  describe "for a created document" do
    let(:database) {
      Ashikawa::Core::Database.new do |config|
        config.url = ARANGO_HOST
      end
    }
    let(:collection) { database["documenttests"] }
    subject { collection.create_document(:name => "The Dude") }
    let(:document_key) { subject.key }

    it "should be possible to manipulate documents and save them" do
      subject["name"] = "Jeffrey Lebowski"
      subject["name"].should == "Jeffrey Lebowski"
      collection.fetch(document_key)["name"].should == "The Dude"
      subject.save
      collection.fetch(document_key)["name"].should == "Jeffrey Lebowski"
    end

    it "should be possible to delete a document" do
      collection.fetch(document_key).delete
      expect {
        collection.fetch(document_key)
      }.to raise_exception Ashikawa::Core::DocumentNotFoundException
    end

    it "should not be possible to delete a document that doesn't exist" do
      expect {
        collection.fetch(123).delete
      }.to raise_exception Ashikawa::Core::DocumentNotFoundException
    end

    it "should be possible to refresh a document" do
      changed_document = collection.fetch(document_key)
      changed_document["name"] = "New Name"
      changed_document.save

      subject["name"].should == "The Dude"
      subject.refresh!
      subject["name"].should == "New Name"
    end
  end
end
