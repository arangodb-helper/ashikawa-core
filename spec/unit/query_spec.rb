require 'unit/spec_helper'
require 'ashikawa-core/query'

describe Ashikawa::Core::Query do
  let(:collection) { double }
  let(:database) { double }

  describe "initialized with collection" do
    subject { Ashikawa::Core::Query.new collection }

    before do
      collection.stub(:name).and_return "example_1"
      collection.stub(:database).and_return double
    end

    describe "get all" do
      it "should list all documents" do
        collection.stub(:send_request).and_return { server_response('simple-queries/all') }
        collection.should_receive(:send_request).with("simple/all", :put => {"collection" => "example_1"})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.all
      end

      it "should be able to limit the number of documents" do
        collection.stub(:send_request).and_return { server_response('simple-queries/all_skip') }
        collection.should_receive(:send_request).with("simple/all", :put => {"collection" => "example_1", "limit" => 1})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.all :limit => 1
      end

      it "should be able to skip documents" do
        collection.stub(:send_request).and_return { server_response('simple-queries/all_limit') }
        collection.should_receive(:send_request).with("simple/all", :put => {"collection" => "example_1", "skip" => 1})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.all :skip => 1
      end
    end

    describe "first by example" do
      let(:example) { {:hello => "world"} }

      it "should find exactly one fitting document" do
        collection.stub(:database).and_return { double }

        collection.stub(:send_request).and_return { server_response('simple-queries/example') }
        collection.should_receive(:send_request).with("simple/first-example", :put =>
          {"collection" => "example_1", "example" => { :hello => "world"}})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.first_example example
      end
    end

    describe "all by example" do
      let(:example) { {:hello => "world"} }

      it "should find all fitting documents" do
        collection.stub(:send_request).and_return { server_response('simple-queries/example') }
        collection.should_receive(:send_request).with("simple/by-example", :put =>
          {"collection" => "example_1", "example" => { :hello => "world"}})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.by_example example
      end

      it "should be able to limit the number of documents" do
        collection.stub(:send_request).and_return { server_response('simple-queries/example') }
        collection.should_receive(:send_request).with("simple/by-example", :put => {"collection" => "example_1", "limit" => 2, "example" => { :hello => "world"}})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.by_example example, :limit => 2
      end

      it "should be able to skip documents" do
        collection.stub(:send_request).and_return { server_response('simple-queries/example') }
        collection.should_receive(:send_request).with("simple/by-example", :put =>
          {"collection" => "example_1", "skip" => 1, "example" => { :hello => "world"}})

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.by_example example, :skip => 1
      end
    end

    describe "near a geolocation" do
      it "should find documents based on latitude/longitude" do
        collection.stub(:send_request).and_return { server_response('simple-queries/near') }
        collection.should_receive(:send_request).with("simple/near", :put => { "collection" => "example_1", "latitude" => 0, "longitude" => 0 })

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.near :latitude => 0, :longitude => 0
      end
    end

    describe "within a radious of a geolocation" do
      it "should look for documents based on latidude/longitude" do
        collection.stub(:send_request).and_return { server_response('simple-queries/within') }
        collection.should_receive(:send_request).with("simple/within" , :put => { "collection" => "example_1", "latitude" => 0, "longitude" => 0, "radius" => 2 })

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.within :latitude => 0, :longitude => 0, :radius => 2
      end
    end

    describe "in a certain range" do
      it "should look for documents with an attribute in that range" do
        arguments = { "collection" => "example_1", "attribute" => "age", "left" => 50, "right" => 60, "closed" => false}
        collection.stub(:send_request).and_return { server_response('simple-queries/range') }
        collection.should_receive(:send_request).with("simple/range" , :put => arguments)

        Ashikawa::Core::Cursor.should_receive(:new)

        subject.in_range :attribute => "age", :left => 50, :right => 60, :closed => false
      end
    end

    describe "with an AQL query" do
      it "should be able to execute it" do
        collection.stub(:database).and_return double
        collection.stub(:send_request).and_return { server_response("cursor/query") }
        collection.should_receive(:send_request).with("cursor", :post => {
          "query" => "FOR u IN users LIMIT 2 RETURN u",
          "count" => true,
          "batchSize" => 2
        })
        Ashikawa::Core::Cursor.should_receive(:new).with(collection.database, server_response("cursor/query"))

        subject.execute "FOR u IN users LIMIT 2 RETURN u", :count => true, :batch_size => 2
      end

      it "should return true when asked if a valid query is valid" do
        query = "FOR u IN users LIMIT 2 RETURN u"

        collection.stub(:send_request).and_return { server_response("query/valid") }
        collection.should_receive(:send_request).with("query", :post => {
          "query" => query
        })

        subject.valid?(query).should be_true
      end

      it "should return false when asked if an invalid query is valid" do
        query = "FOR u IN users LIMIT 2"

        collection.stub(:send_request) do
          raise Ashikawa::Core::BadSyntax
        end
        collection.should_receive(:send_request).with("query", :post => {
          "query" => query
        })

        subject.valid?(query).should be_false
      end
    end
  end

  describe "initialized with database" do
    subject { Ashikawa::Core::Query.new database}

    it "should throw an exception when a simple query is executed" do
      [:all, :by_example, :first_example, :near, :within, :in_range].each do |method|
        expect { subject.send method }.to raise_error Ashikawa::Core::NoCollectionProvidedException
      end
    end

    describe "with an AQL query" do
      it "should be able to execute it" do
        database.stub(:send_request).and_return { server_response("cursor/query") }
        database.should_receive(:send_request).with("cursor", :post => {
          "query" => "FOR u IN users LIMIT 2 RETURN u",
          "count" => true,
          "batchSize" => 2
        })
        Ashikawa::Core::Cursor.should_receive(:new).with(database, server_response("cursor/query"))

        subject.execute "FOR u IN users LIMIT 2 RETURN u", :count => true, :batch_size => 2
      end

      it "should return true when asked if a valid query is valid" do
        query = "FOR u IN users LIMIT 2 RETURN u"

        database.stub(:send_request).and_return { server_response("query/valid") }
        database.should_receive(:send_request).with("query", :post => {
          "query" => query
        })

        subject.valid?(query).should be_true
      end

      it "should return false when asked if an invalid query is valid" do
        query = "FOR u IN users LIMIT 2"

        database.stub(:send_request) do
          raise Ashikawa::Core::BadSyntax
        end
        database.should_receive(:send_request).with("query", :post => {
          "query" => query
        })

        subject.valid?(query).should be_false
      end
    end
  end
end
