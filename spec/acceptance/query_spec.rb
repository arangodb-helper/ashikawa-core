# -*- encoding : utf-8 -*-
require 'acceptance/spec_helper'

describe "Queries" do
  let(:database) { DATABASE }
  let(:collection) { database["my_collection"] }

  describe "AQL query via the database" do
    it "should return the documents" do
      query = "FOR u IN my_collection FILTER u.bowling == true RETURN u"
      options = { batch_size: 2, count: true }

      collection.create_document({ "name" => "Jeff Lebowski",    "bowling" => true })
      collection.create_document({ "name" => "Walter Sobchak",   "bowling" => true })
      collection.create_document({ "name" => "Donny Kerabatsos", "bowling" => true })
      collection.create_document({ "name" => "Jeffrey Lebowski", "bowling" => false })

      names = database.query.execute(query, options).map { |person| person["name"] }
      expect(names).to     include "Jeff Lebowski"
      expect(names).not_to include "Jeffrey Lebowski"
    end

    it "should be possible to validate" do
      valid_query = "FOR u IN my_collection FILTER u.bowling == true RETURN u"
      expect(database.query.valid?(valid_query)).to be_true

      invalid_query = "FOR u IN my_collection FILTER u.bowling == true"
      expect(database.query.valid?(invalid_query)).to be_false
    end
  end

  describe "simple query via collection object" do
    subject { collection }
    before(:each) { subject.truncate! }

    it "should return all documents of a collection" do
      subject.create_document({ name: "testname", age: 27})
      expect(subject.query.all.first["name"]).to eq("testname")
    end

    it "should be possible to limit and skip results" do
      subject.create_document({ name: "test1"})
      subject.create_document({ name: "test2"})
      subject.create_document({ name: "test3"})

      expect(subject.query.all(limit: 2).length).to eq(2)
      expect(subject.query.all(skip: 2).length).to eq(1)
    end

    it "should be possible to query documents by example" do
      subject.create_document({ "name" => "Random Document" })
      result = subject.query.by_example name: "Random Document"
      expect(result.length).to eq(1)
    end

    it "should be possible to query first document by example" do
      subject.create_document({ "name" => "Single Document" })
      result = subject.query.first_example name: "Single Document"
      expect(result["name"]).to eq("Single Document")
    end

    describe "query by geo coordinates" do
      before :each do
        subject.add_index :geo, on: [:latitude, :longitude]
        subject.create_document({ "name" => "cologne", "latitude" => 50.948045, "longitude" => 6.961212 })
        subject.create_document({ "name" => "san francisco", "latitude" => -122.395899, "longitude" => 37.793621 })
      end

      it "should be possible to query documents near a certain location" do
        found_places = subject.query.near latitude: 50, longitude: 6
        expect(found_places.first["name"]).to eq("cologne")
      end

      it "should be possible to query documents within a certain range" do
        found_places = subject.query.within latitude: 50.948040, longitude: 6.961210, radius: 2
        expect(found_places.length).to eq(1)
        expect(found_places.first["name"]).to eq("cologne")
      end
    end

    describe "queries by integer ranges" do
      before :each do
        subject.add_index :skiplist, on: [:age]
        subject.create_document({ "name" => "Georg", "age" => 12 })
        subject.create_document({ "name" => "Anne", "age" => 21 })
        subject.create_document({ "name" => "Jens", "age" => 49 })
      end

      it "should be possible to query documents for numbers in a certain range" do
        found_people = subject.query.in_range attribute: "age", left: 20, right: 30, closed: true
        expect(found_people.length).to eq(1)
        expect(found_people.first["name"]).to eq("Anne")
      end
    end
  end
end
