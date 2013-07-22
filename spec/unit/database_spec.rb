require 'unit/spec_helper'
require 'ashikawa-core/database'

describe Ashikawa::Core::Database do
  subject { Ashikawa::Core::Database }

  before :each do
    double(Ashikawa::Core::Connection)
    double(Ashikawa::Core::Collection)
    double(Ashikawa::Core::Cursor)
    double(Ashikawa::Core::Transaction)
    @connection = double("connection", :host => "localhost", :port => 8529, :scheme => "http")
  end

  it "should initialize with a connection" do
    @connection.stub(:host) { "localhost" }
    @connection.stub(:port) { 8529 }

    database = subject.new do |config|
      config.connection = @connection
    end
    database.host.should == "localhost"
    database.port.should == 8529
  end

  it "should initialize with a connection string" do
    Ashikawa::Core::Connection.stub(:new).with("http://localhost:8529", {
      :logger => nil,
      :adapter => nil
    }).and_return(double)
    Ashikawa::Core::Connection.should_receive(:new).with("http://localhost:8529", {
      :logger => nil,
      :adapter => nil
    })

    subject.new do |config|
      config.url = "http://localhost:8529"
    end
  end

  it "should initialize with a connection string and logger" do
    logger = double
    Ashikawa::Core::Connection.stub(:new).with("http://localhost:8529", {
      :logger => logger,
      :adapter => nil
    }).and_return(double)
    Ashikawa::Core::Connection.should_receive(:new).with("http://localhost:8529", {
      :logger => logger,
      :adapter => nil
    })

    subject.new do |config|
      config.url = "http://localhost:8529"
      config.logger = logger
    end
  end

  it "should initialize with a connection string and adapter" do
    adapter = double
    Ashikawa::Core::Connection.stub(:new).with("http://localhost:8529", {
      :logger => nil,
      :adapter => adapter
    }).and_return(double)
    Ashikawa::Core::Connection.should_receive(:new).with("http://localhost:8529", {
      :logger => nil,
      :adapter => adapter
    })

    subject.new do |config|
      config.url = "http://localhost:8529"
      config.adapter = adapter
    end
  end

  it "should throw an argument error when neither url nor connection was provided" do
    adapter = double
    logger = double

    expect {
      subject.new do |config|
        config.adapter = adapter
        config.logger = logger
      end
    }.to raise_error(ArgumentError, /either an url or a connection/)
  end

  it "should create a query" do
    database = subject.new do |config|
      config.connection = @connection
    end

    double Ashikawa::Core::Query
    Ashikawa::Core::Query.stub(:new)
    Ashikawa::Core::Query.should_receive(:new).exactly(1).times.with(database)

    database.query
  end

  describe "initialized database" do
    subject {
      Ashikawa::Core::Database.new do |config|
        config.connection = @connection
      end
    }

    it "should delegate authentication to the connection" do
      @connection.should_receive(:authenticate_with).with({ :username => "user", :password => "password" })

      subject.authenticate_with :username => "user", :password => "password"
    end

    it "should fetch all available non-system collections" do
      @connection.stub(:send_request) {|path| server_response("collections/all") }
      @connection.should_receive(:send_request).with("collection")

      (0..1).each do |k|
        Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/all")["collections"][k])
      end

      subject.collections.length.should == 2
    end

    it "should fetch all available non-system collections" do
      @connection.stub(:send_request) {|path| server_response("collections/all") }
      @connection.should_receive(:send_request).with("collection")

      Ashikawa::Core::Collection.should_receive(:new).exactly(5).times

      subject.system_collections.length.should == 5
    end

    it "should create a non volatile collection by default" do
      @connection.stub(:send_request) { |path| server_response("collections/60768679") }
      @connection.should_receive(:send_request).with("collection",
        :post => { :name => "volatile_collection"})

      Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/60768679"))

      subject.create_collection("volatile_collection")
    end

    it "should create a volatile collection when asked" do
      @connection.stub(:send_request) { |path| server_response("collections/60768679") }
      @connection.should_receive(:send_request).with("collection",
        :post => { :name => "volatile_collection", :isVolatile => true})

      Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/60768679"))

      subject.create_collection("volatile_collection", :is_volatile => true)
    end

    it "should create an autoincrement collection when asked" do
      @connection.should_receive(:send_request).with("collection",
        :post => { :name => "autoincrement_collection", :keyOptions => {
          :type => "autoincrement",
          :offset => 0,
          :increment => 10,
          :allowUserKeys => false
        }
      })

      Ashikawa::Core::Collection.should_receive(:new)

      subject.create_collection("autoincrement_collection", :key_options => {
        :type => :autoincrement,
        :offset => 0,
        :increment => 10,
        :allow_user_keys => false
      })
    end

    it "should create an edge collection when asked" do
      @connection.stub(:send_request) { |path| server_response("collections/60768679") }
      @connection.should_receive(:send_request).with("collection",
        :post => { :name => "volatile_collection", :type => 3})

      Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/60768679"))

      subject.create_collection("volatile_collection", :content_type => :edge)
    end

    it "should fetch a single collection if it exists" do
      @connection.stub(:send_request) { |path| server_response("collections/60768679") }
      @connection.should_receive(:send_request).with("collection/60768679")

      Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/60768679"))

      subject.collection(60768679)
    end

    it "should fetch a single collection with the array syntax" do
      @connection.stub(:send_request) { |path| server_response("collections/60768679") }
      @connection.should_receive(:send_request).with("collection/60768679")

      Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/60768679"))

      subject[60768679]
    end

    it "should create a single collection if it doesn't exist" do
      @connection.stub :send_request do |path, method|
        method ||= {}
        if method.has_key? :post
          server_response("collections/60768679")
        else
          raise Ashikawa::Core::CollectionNotFoundException
        end
      end
      @connection.should_receive(:send_request).with("collection/new_collection")
      @connection.should_receive(:send_request).with("collection", :post => { :name => "new_collection"})

      Ashikawa::Core::Collection.should_receive(:new).with(subject, server_response("collections/60768679"))

      subject['new_collection']
    end

    it "should send a request via the connection object" do
      @connection.should_receive(:send_request).with("my/path", :post => { :data => "mydata" })

      subject.send_request "my/path", :post => { :data => "mydata" }
    end

    let(:js_function) { double }
    let(:collections) { double }
    let(:transaction) { double }

    it "should create a transaction" do
      Ashikawa::Core::Transaction.should_receive(:new).with(subject, js_function, collections).and_return { transaction }
      subject.create_transaction(js_function, collections).should == transaction
    end
  end
end
