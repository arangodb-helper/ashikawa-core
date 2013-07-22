require 'unit/spec_helper'
require 'ashikawa-core/edge'

describe Ashikawa::Core::Edge do
  let(:database) { double }
  let(:raw_data) {
    {
      "_id" => "1234567/2345678",
      "_key" => "2345678",
      "_rev" => "3456789",
      "_from" => "7848004/9289796",
      "_to" => "7848004/9355332",
      "first_name" => "The",
      "last_name" => "Dude"
    }
  }
  subject { Ashikawa::Core::Edge }

  it "should initialize data" do
    document = subject.new(database, raw_data)
    document.id.should == "1234567/2345678"
    document.key.should == "2345678"
    document.revision.should == "3456789"
  end

  describe "initialized edge" do
    subject { Ashikawa::Core::Edge.new(database, raw_data)}

    it "should be deletable" do
      database.should_receive(:send_request).with("edge/#{raw_data['_id']}",
        { :delete => {} }
      )

      subject.delete
    end

    it "should store changes to the database" do
      database.should_receive(:send_request).with("edge/#{raw_data['_id']}",
        { :put => { "first_name" => "The", "last_name" => "Other" } }
      )

      subject["last_name"] = "Other"
      subject.save
    end

    it "should know the ID of the 'from' document" do
      subject.from_id.should == "7848004/9289796"
    end

    it "should know the ID of the 'to' document" do
      subject.to_id.should == "7848004/9355332"
    end
  end
end
