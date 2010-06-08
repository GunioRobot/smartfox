require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SmartFox::Packet do
  it "should parse system packets" do
    SYSTEM_PACKET = "<msg t='sys'><body action='apiOK' r='0'></body></msg>\0"

    packet = SmartFox::Packet.parse(SYSTEM_PACKET)

    packet.header.should == SmartFox::Client::HEADER_SYSTEM
    packet.action.should == SmartFox::Client::ACTION_API_OK
    packet.room.should == 0
    packet.data.should be_nil
  end

  it "should parse extended packets" do
    EXTENDED_PACKET = "<msg t='xt'><body action='xtRes' r='-1'><![CDATA[<dataObj><var n='uid' t='n'>481942</var><var n='_cmd' t='s'>logOK</var><obj o='ent' t='a'><var n='chat_priv' t='s'>1</var><var n='init_block' t='s'>1</var><var n='chat_join_rooms' t='s'>10</var><var n='chat_occupancy' t='s'>200</var><var n='init_chat' t='s'>1</var><var n='chat_admin' t='s'>0</var></obj></dataObj>]]></body></msg>\0"
    
    packet = SmartFox::Packet.parse(EXTENDED_PACKET)
    
    packet.header.should == SmartFox::Client::HEADER_EXTENDED
    packet.action.should == SmartFox::Client::EXTENDED_RESPONSE
    packet.room.should == -1
    packet.data.should == { :uid => 481942, :_cmd => 'logOK', :ent => { :chat_priv => "1", :init_block => "1", :chat_join_rooms => "10", :chat_occupancy => "200", :init_chat => "1", :chat_admin => "0" } }

  end
end