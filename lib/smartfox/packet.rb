require 'libxml'

class SmartFox::Packet
  attr_reader :action, :header, :room, :data

  def initialize(header, action, body, room = 0, extra = nil)
    @header = header
    @action = action
    @room = room.to_i
    @body = body
    @data = (@header == SmartFox::Client::HEADER_EXTENDED ? SmartFox::Packet.parse_extended(extra) : extra)
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
    SmartFox::Logger.debug "SmartFox::Packet.parse_xml('#{data}')"
    document = LibXML::XML::Parser.string(data).parse
    header = document.root['t']
    action = document.root.child['action']
    room = document.root.child['r']
    extra = document.root.child.children? ? document.root.child.children : nil
    new(header, action, document.root.child, room, extra)
  end

  def self.parse_json(data)
    SmartFox::Logger.debug "SmartFox::Packet.parse_json('#{data}')"
  end

  def self.parse_string(data)
    SmartFox::Logger.debug "SmartFox::Packet.parse_string('#{data}')"
  end

  def self.parse_extended(data)
    SmartFox::Logger.debug "SmartFox::Packet.parse_extended('#{data}')"
    document = LibXML::XML::Parser.string(data.first.content).parse
    parse_extended_object document.root
  end

  def self.parse_extended_scaler(node)
    case node['t']
    when 'n'
      node.content.to_i
    when 's'
      node.content
    when 'b'
      node.content == "1"
    end
  end

  def self.parse_extended_object(node)
    result = {}

    node.children.each do |child|
      case child.name
      when 'var'
        result[child["n"].to_sym] = parse_extended_scaler(child)
      when 'obj'
        result[child["o"].to_sym] = parse_extended_object(child)
      end
    end

    result
  end
end