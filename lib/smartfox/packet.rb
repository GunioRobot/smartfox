require 'libxml'

class SmartFox::Packet
  attr_reader :action, :header, :room, :data

  def initialize(header, action, room = 0, extra = nil)
    @header = header
    @action = action
    @room = room
    @extra = extra
  end

  def self.parse(data)
    case data[0, 1]
    when '<'
      return parse_xml(data)
    when '{'
      return parse_json(data)
    else
      return parse_string(data)
    end
  end

  def self.parse_xml(data)
    SmartFox::Logger.debug "SmartFox::Packet#parse_xml('#{data}')"
    document = LibXML::XML::Parser.string(data).parse
    header = document.root['t']
    action = document.root.child['action']
    room = document.root.child['r']
    extra = document.root.child.child
    new(header, action, room, extra)
  end

  def self.parse_json(data)
    SmartFox::Logger.debug "SmartFox::Packet#parse_json('#{data}')"
  end

  def self.parse_string(data)
    SmartFox::Logger.debug "SmartFox::Packet#parse_string('#{data}')"
  end
end