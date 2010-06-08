require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SmartFox::Client do
  before(:each) do
    @connection = SmartFox::Client.new()
  end

  after(:each) do
    @connection.disconnect if @connection
  end

  it "should create a connection" do
    login_waiter = Waiter.new
    @connection.connect
  end

  it "should be connected after calling connect" do
    login_waiter = Waiter.new
    @connection.connect
    @connection.connected?.should be_true
  end

  it "should raise the 'connected' event after connecting" do
    connected_waiter = Waiter.new
    @connection.add_handler(:connected) { |connection| puts "connected_waiter fired"; connected_waiter.fire }
    @connection.connect
    connected_waiter.wait
  end

  it "should fail when attempting to connect to a non-existant server" do
    TCPSocket.should_receive(:new).once.with('localhost', 9339).and_raise(Errno::ETIMEDOUT)
    lambda { @connection.connect }.should raise_error(SmartFox::Client::ConnectionFailureError)
  end

  it "should login to the default install" do
    login_waiter = Waiter.new
    @connection.add_handler(:connected) { |connection| connection.login 'simpleChat', 'penwellr' }
    @connection.add_handler(:logged_in) { login_waiter.fire }
    @connection.connect

    login_waiter.wait(10)
  end
  
  it "should fall back on BlueBox if needed"
end
