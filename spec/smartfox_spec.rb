require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Smartfox" do
  it "should create a connection" do
    connection = SmartFox::Client.new(:server => 'localhost')
    connection.connect
  end

  it "should be connected after calling connect" do
    connection = SmartFox::Client.new()
    connection.connect
    connection.connected?.should be_true
  end

  it "should raise the 'connected' event after connecting" do
    connected = false
    connection = SmartFox::Client.new()
    connection.add_handler(:connected) { |connection| connected = true}
    connection.connect
    connected.should be_true
  end

  it "should fail when attempting to connect to a non-existant server" do
    connection = SmartFox::Client.new(:server => '10.2.3.4')
    lambda { connection.connect }.should raise_error(SmartFox::Client::ConnectionFailureError)
  end
  
  it "should fall back on BlueBox if needed"
end
