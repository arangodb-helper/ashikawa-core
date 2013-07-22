require 'unit/spec_helper'
require 'ashikawa-core/transaction'

describe Ashikawa::Core::Transaction do
  let(:db) { double }
  let(:action) { double }

  describe "creating a transaction" do
    subject { Ashikawa::Core::Transaction }

    it "should be initialized with only write collections" do
      transaction = subject.new(db, action, :write => [
        "collection_1"
      ])

      transaction.write_collections.should == ["collection_1"]
    end

    it "should be initialized with only read collections" do
      transaction = subject.new(db, action, :read => [
        "collection_1"
      ])

      transaction.read_collections.should == ["collection_1"]
    end
  end

  describe "using a transaction" do
    let(:read_and_write_collections) do
      { :read => ["collection_1"], :write => ["collection_2"] }
    end

    let(:only_read_collection) do
      { :read => ["collection_1"] }
    end

    let(:only_write_collection) do
      { :write => ["collection_1"] }
    end

    subject { Ashikawa::Core::Transaction.new(db, action, read_and_write_collections) }

    it "should be possible to activate waiting for sync" do
      subject.wait_for_sync.should == false
      subject.wait_for_sync = true
      subject.wait_for_sync.should == true
    end

    it "should be possible to set the lock timeout" do
      subject.lock_timeout.should == nil
      subject.lock_timeout = 30
      subject.lock_timeout.should == 30
    end

    describe "execute" do
      let(:response) { double }
      let(:result) { double }
      let(:wait_for_sync) { double }
      let(:lock_timeout) { double }
      let(:action_params) { double }

      before {
        response.stub(:[])
        db.stub(:send_request).and_return { response }
      }

      it "should return the result from the database" do
        response.should_receive(:[]).with("result").and_return { result }
        db.should_receive(:send_request).and_return { response }
        subject.execute.should == result
      end

      it "should post to `transaction` endpoint" do
        db.should_receive(:send_request).with("transaction", :post => an_instance_of(Hash))
        subject.execute
      end

      it "should only send the read collection if no write collection was provided" do
        transaction = Ashikawa::Core::Transaction.new(db, action, only_read_collection)
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:collections => only_read_collection)
        })
        transaction.execute
      end

      it "should send the information about the read and write collections" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:collections => read_and_write_collections)
        })
        subject.execute
      end

      it "should only send the write collection if no read collection was provided" do
        transaction = Ashikawa::Core::Transaction.new(db, action, only_write_collection)
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:collections => only_write_collection)
        })
        transaction.execute
      end

      it "should send the information about the action" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:action => action)
        })
        subject.execute
      end

      it "should send with wait for sync set to false by default" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:waitForSync => false)
        })
        subject.execute
      end

      it "should send with wait for sync set to the value provided by the user" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:waitForSync => wait_for_sync)
        })
        subject.wait_for_sync = wait_for_sync
        subject.execute
      end

      it "should not send lock timeout by default" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_not_including(:lockTimeout => anything)
        })
        subject.execute
      end

      it "should send the configured lock timeout" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:lockTimeout => lock_timeout)
        })
        subject.lock_timeout = lock_timeout
        subject.execute
      end

      it "should send the arguments object if it was provided" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_including(:params => action_params)
        })
        subject.execute(action_params)
      end

      it "should not send params by default" do
        db.should_receive(:send_request).with(anything, {
          :post => hash_not_including(:params => anything)
        })
        subject.execute
      end
    end
  end
end
