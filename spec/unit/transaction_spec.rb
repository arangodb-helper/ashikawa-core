# -*- encoding : utf-8 -*-
require 'unit/spec_helper'
require 'ashikawa-core/transaction'

describe Ashikawa::Core::Transaction do
  let(:db) { double }
  let(:action) { double }

  describe "creating a transaction" do
    subject { Ashikawa::Core::Transaction }

    it "should be initialized with only write collections" do
      transaction = subject.new(db, action, write: [ "collection_1" ])
      expect(transaction.write_collections).to eq(["collection_1"])
    end

    it "should be initialized with only read collections" do
      transaction = subject.new(db, action, read: [ "collection_1" ])
      expect(transaction.read_collections).to eq(["collection_1"])
    end
  end

  describe "using a transaction" do
    let(:read_and_write_collections) {{
      read: ["collection_1"],
      write: ["collection_2"]
    }}

    let(:only_read_collection) {{
      read: ["collection_1"]
    }}

    let(:only_write_collection) {{
      write: ["collection_1"]
    }}

    subject { Ashikawa::Core::Transaction.new(db, action, read_and_write_collections) }

    it "should be possible to activate waiting for sync" do
      expect(subject.wait_for_sync).to be_false
      subject.wait_for_sync = true
      expect(subject.wait_for_sync).to be_true
    end

    it "should be possible to set the lock timeout" do
      expect(subject.lock_timeout).to be_nil
      subject.lock_timeout = 30
      expect(subject.lock_timeout).to be 30
    end

    describe "execute" do
      let(:response) { double }
      let(:result) { double }
      let(:wait_for_sync) { double }
      let(:lock_timeout) { double }
      let(:action_params) { double }

      before {
        allow(response).to receive(:[])
        allow(db).to receive(:send_request)
          .and_return { response }
      }

      it "should return the result from the database" do
        expect(response).to receive(:[])
          .with("result")
          .and_return(result)
        expect(db).to receive(:send_request)
          .and_return { response }
        expect(subject.execute).to eq(result)
      end

      it "should post to `transaction` endpoint" do
        expect(db).to receive(:send_request)
          .with("transaction", post: an_instance_of(Hash))
        subject.execute
      end

      it "should only send the read collection if no write collection was provided" do
        transaction = Ashikawa::Core::Transaction.new(db, action, only_read_collection)
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(collections: only_read_collection) })
        transaction.execute
      end

      it "should send the information about the read and write collections" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(collections: read_and_write_collections) })
        subject.execute
      end

      it "should only send the write collection if no read collection was provided" do
        transaction = Ashikawa::Core::Transaction.new(db, action, only_write_collection)
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(collections: only_write_collection) })
        transaction.execute
      end

      it "should send the information about the action" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(action: action) })
        subject.execute
      end

      it "should send with wait for sync set to false by default" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(waitForSync: false) })
        subject.execute
      end

      it "should send with wait for sync set to the value provided by the user" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(waitForSync: wait_for_sync) })
        subject.wait_for_sync = wait_for_sync
        subject.execute
      end

      it "should not send lock timeout by default" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_not_including(lockTimeout: anything) })
        subject.execute
      end

      it "should send the configured lock timeout" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(lockTimeout: lock_timeout) })
        subject.lock_timeout = lock_timeout
        subject.execute
      end

      it "should send the arguments object if it was provided" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_including(params: action_params) })
        subject.execute(action_params)
      end

      it "should not send params by default" do
        expect(db).to receive(:send_request)
          .with(anything, { post: hash_not_including(params: anything) })
        subject.execute
      end
    end
  end
end
