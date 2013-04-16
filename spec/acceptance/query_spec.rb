require 'acceptance/spec_helper'

describe "Queries" do
  let(:database) { Ashikawa::Core::Database.new do |config|
      config.url = ARANGO_HOST
    end
  }
  let(:collection) { database["my_collection"] }

  describe "AQL query via the database" do
    it "should return the documents" do
      query = "FOR u IN my_collection FILTER u.bowling == true RETURN u"
      options = { :batch_size => 2, :count => true }

      collection << { "name" => "Jeff Lebowski",    "bowling" => true }
      collection << { "name" => "Walter Sobchak",   "bowling" => true }
      collection << { "name" => "Donny Kerabatsos", "bowling" => true }
      collection << { "name" => "Jeffrey Lebowski", "bowling" => false }

      names = database.query.execute(query, options).map { |person| person["name"] }
      names.should     include "Jeff Lebowski"
      names.should_not include "Jeffrey Lebowski"
    end

    it "should be possible to validate" do
      valid_query = "FOR u IN my_collection FILTER u.bowling == true RETURN u"
      database.query.valid?(valid_query).should be_true

      invalid_query = "FOR u IN my_collection FILTER u.bowling == true"
      database.query.valid?(invalid_query).should be_false
    end
  end

  describe "simple query via collection object" do
    subject { collection }
    before(:each) { subject.truncate! }

    it "should return all documents of a collection" do
      subject << { :name => "testname", :age => 27}
      subject.query.all.first["name"].should == "testname"
    end

    it "should be possible to limit and skip results" do
      subject << { :name => "test1"}
      subject << { :name => "test2"}
      subject << { :name => "test3"}

      subject.query.all(:limit => 2).length.should == 2
      subject.query.all(:skip => 2).length.should == 1
    end

    it "should be possible to query documents by example" do
      subject << { "name" => "Random Document" }
      result = subject.query.by_example :name => "Random Document"
      result.length.should == 1
    end

    it "should be possible to query first document by example" do
      subject << { "name" => "Single Document" }
      result = subject.query.first_example :name => "Single Document"
      result.length.should == 1
    end

    describe "query by geo coordinates" do
      before :each do
        subject.add_index :geo, :on => [:latitude, :longitude]
        subject << { "name" => "cologne", "latitude" => 50.948045, "longitude" => 6.961212 }
        subject << { "name" => "san francisco", "latitude" => -122.395899, "longitude" => 37.793621 }
      end

      it "should be possible to query documents near a certain location" do
        found_places = subject.query.near :latitude => 50, :longitude => 6
        found_places.first["name"].should == "cologne"
      end

      it "should be possible to query documents within a certain range" do
        found_places = subject.query.within :latitude => 50.948040, :longitude => 6.961210, :radius => 2
        found_places.length.should == 1
        found_places.first["name"].should == "cologne"
      end
    end

    describe "queries by integer ranges" do
      before :each do
        subject.add_index :skiplist, :on => [:age]
        subject << { "name" => "Georg", "age" => 12 }
        subject << { "name" => "Anne", "age" => 21 }
        subject << { "name" => "Jens", "age" => 49 }
      end

      it "should be possible to query documents for numbers in a certain range" do
        found_people = subject.query.in_range :attribute => "age", :left => 20, :right => 30, :closed => true
        found_people.length.should == 1
        found_people.first["name"].should == "Anne"
      end
    end
  end
end
