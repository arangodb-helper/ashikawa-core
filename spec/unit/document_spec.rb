require 'unit/spec_helper'
require 'ashikawa-core/document'

describe Ashikawa::Core::Document do
  let(:database) { double }
  let(:raw_data) {
    {
      "_id" => "1234567/2345678",
      "_key" => "2345678",
      "_rev" => "3456789",
      "first_name" => "The",
      "last_name" => "Dude"
    }
  }
  let(:raw_data_without_id) {
    {
      "first_name" => "The",
      "last_name" => "Dude"
    }
  }
  subject { Ashikawa::Core::Document }

  it "should initialize data with ID" do
    document = subject.new database, raw_data
    document.id.should == "1234567/2345678"
    document.key.should == "2345678"
    document.revision.should == "3456789"
  end

  it "should initialize data without ID" do
    document = subject.new database, raw_data_without_id
    document.id.should == :not_persisted
    document.revision.should == :not_persisted
  end

  describe "initialized document with ID" do
    subject { Ashikawa::Core::Document.new database, raw_data }

    it "should return the correct value for an existing attribute" do
      subject["first_name"].should be(raw_data["first_name"])
    end

    it "should return nil for an non-existing attribute" do
      subject["no_name"].should be_nil
    end

    it "should be deletable" do
      database.should_receive(:send_request).with("document/#{raw_data['_id']}",
        { :delete => {} }
      )

      subject.delete
    end

    it "should store changes to the database" do
      database.should_receive(:send_request).with("document/#{raw_data['_id']}",
        { :put => { "first_name" => "The", "last_name" => "Other" } }
      )

      subject["last_name"] = "Other"
      subject.save
    end

    it "should be convertable to a hash" do
      hash = subject.hash
      hash.should be_instance_of Hash
      hash["first_name"].should == subject["first_name"]
    end

    it "should be refreshable" do
      database.should_receive(:send_request).with("document/#{raw_data['_id']}", {}).and_return {
        { "name" => "Jeff" }
      }

      refreshed_subject = subject.refresh!
      refreshed_subject.should == subject
      subject["name"].should == "Jeff"
    end
  end

  describe "initialized document without ID" do
    subject { Ashikawa::Core::Document.new database, raw_data_without_id }

    it "should return the correct value for an existing attribute" do
      subject["first_name"].should be(raw_data_without_id["first_name"])
    end

    it "should return nil for an non-existing attribute" do
      subject["no_name"].should be_nil
    end

    it "should not be deletable" do
      database.should_not_receive :send_request
      expect { subject.delete }.to raise_error Ashikawa::Core::DocumentNotFoundException
    end

    it "should not store changes to the database" do
      database.should_not_receive :send_request
      expect { subject.save }.to raise_error Ashikawa::Core::DocumentNotFoundException
    end
  end

  describe "Deprecated methods" do
    subject { Ashikawa::Core::Document.new database, raw_data_without_id }

    it "should mark `to_hash` as deprecated" do
      subject.should_receive(:hash)
      subject.should_receive(:warn).with("`to_hash` is deprecated, please use `hash`")
      subject.to_hash
    end
  end
end
