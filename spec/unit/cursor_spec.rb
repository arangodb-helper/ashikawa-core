require 'unit/spec_helper'
require 'ashikawa-core/cursor'

describe Ashikawa::Core::Cursor do
  subject { Ashikawa::Core::Cursor }

  before :each do
    @database = double()
    mock Ashikawa::Core::Document
  end

  it "should create a cursor for a non-complete batch" do
    my_cursor = subject.new @database, server_response("cursor/26011191")
    my_cursor.id.should        == "26011191"
    my_cursor.length.should    == 5
  end

  it "should create a cursor for the last batch" do
    my_cursor = subject.new @database, server_response("cursor/26011191-3")
    my_cursor.id.should be_nil
    my_cursor.length.should == 5
  end

  describe "existing cursor" do
    subject { Ashikawa::Core::Cursor.new @database,
      server_response("cursor/26011191")
    }

    it "should iterate over all documents of a cursor when given a block" do
      first = true

      @database.stub(:send_request).with("cursor/26011191", :put => {}) do
        if first
          first = false
          server_response("cursor/26011191-2")
        else
          server_response("cursor/26011191-3")
        end
      end
      @database.should_receive(:send_request).twice

      Ashikawa::Core::Document.stub(:new)
      Ashikawa::Core::Document.should_receive(:new).exactly(5).times

      subject.each { |document| }
    end

    it "should return an enumerator to go over all documents of a cursor when given no block" do
      pending "This fails on 1.8.7 because of an old backports version" if RUBY_VERSION == "1.8.7"

      first = true

      @database.stub(:send_request).with("cursor/26011191", :put => {}) do
        if first
          first = false
          server_response("cursor/26011191-2")
        else
          server_response("cursor/26011191-3")
        end
      end
      @database.should_receive(:send_request).twice

      Ashikawa::Core::Document.stub(:new)
      Ashikawa::Core::Document.should_receive(:new).exactly(5).times

      enumerator = subject.each
      enumerator.next
      enumerator.next
      enumerator.next
      enumerator.next
      enumerator.next
      expect { enumerator.next }.to raise_exception(StopIteration)
    end

    it "should be deletable" do
      @database.stub(:send_request)
      @database.should_receive(:send_request).with("cursor/26011191",
        :delete => {})

      subject.delete
    end

    it "should be enumerable" do
      first = true

      @database.stub(:send_request).with("cursor/26011191", :put => {}) do
        if first
          first = false
          server_response("cursor/26011191-2")
        else
          server_response("cursor/26011191-3")
        end
      end
      @database.should_receive(:send_request).twice

      Ashikawa::Core::Document.stub(:new).and_return { 1 }
      Ashikawa::Core::Document.should_receive(:new).exactly(5).times

      subject.map{|i| i}[0].should == 1
    end

    it "should return edge objects when recieving data from an edge collection" do
      @database.stub(:send_request).with("cursor/26011191", :put => {}) do
        server_response("cursor/edges")
      end
      @database.should_receive(:send_request).once

      Ashikawa::Core::Edge.stub(:new).and_return { 1 }
      Ashikawa::Core::Edge.should_receive(:new).exactly(2).times

      subject.each { |document| }
    end

  end
end
