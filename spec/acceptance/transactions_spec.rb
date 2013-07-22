require 'acceptance/spec_helper'

describe "Transactions" do
  subject {
    Ashikawa::Core::Database.new do |config|
      config.url = ARANGO_HOST
    end
  }

  before :each do
    subject.collections.each { |collection| collection.delete }
    subject["collection_1"]
    subject["collection_2"]
    subject["collection_3"]
  end

  let(:js_function) { "function (x) { return x.a; }" }

  it "should create and execute a transaction" do
    transaction = subject.create_transaction(js_function,
      :write => ["collection_1", "collection_2"],
      :read =>  ["collection_3"]
    )

    transaction.wait_for_sync = true
    transaction.lock_timeout = 14

    transaction.execute({ :a => 5 }).should == 5
  end
end
