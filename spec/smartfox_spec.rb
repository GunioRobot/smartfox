require 'json'

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SmartFox::Client do
  def transport
    @connection.instance_variable_get(:@transport)
  end

  def expect_send_data
    transport.should_receive(:send_data) do |data|
      yield data
    end
  end

  def login_to_connection
    login_waiter = Waiter.new
    @connection.add_handler(:connected) { |connection| connection.login 'simpleChat', 'penwellr' }
    @connection.add_handler(:logged_in) { login_waiter.fire }
    @connection.connect

    login_waiter.wait(10)
  end

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

  it "should properly serialize extended json packets" do
    @connection.connect
    expect_send_data do |data|
      object = JSON.parse(data.chop)
      object.should == { "t" => 'xt', "b" => { "x" => 'ManChatXT', "c" => 'grlbk', "r" => 6, "p" => {} } }
    end

    @connection.send_extended('ManChatXT', 'grlbk', :room => 6, :format => :json)
  end

  it "should retrieve the room list asyncronously" do
    login_to_connection
    updated_waiter = Waiter.new
    room_list = nil
    @connection.add_handler(:rooms_updated) { |client, rooms| room_list = rooms; updated_waiter.fire }
    @connection.refresh_rooms
    updated_waiter.wait

    room_list.should_not be_blank
  end
  
  it "should fall back on BlueBox if needed"
end
