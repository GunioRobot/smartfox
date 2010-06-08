require 'builder'
require 'libxml'

class SmartFox::Client
  class ConnectionFailureError < SmartFox::SmartFoxError; end
  class ApiIncompatibleError < SmartFox::SmartFoxError; end
  class TransportTimeoutError < SmartFox::SmartFoxError; end

  attr_reader :connected, :room_list, :buddy_list, :server, :port
  alias_method :connected?, :connected
  
  CLIENT_VERSION = "1.5.8"
  CONNECTION_TIMEOUT = 5
  TRANSPORTS = [ SmartFox::Socket::Connection, SmartFox::BlueBox::Connection ]

  HEADER_SYSTEM = 'sys'
  ACTION_VERSION_CHECK = 'verChk'
  ACTION_API_OK = 'apiOK'
  ACTION_API_OBSOLETE = 'apiKO'
  
  def initialize(options = {})
    @room_list = {}
    @connected = false
    @buddy_list = []
    @user_id = options[:user_id]
    @user_name = options[:user_name]
    @server = options[:server] || 'localhost'
    @port = options[:port]
    @events = {}
  end
  
  def connect()
    unless @connected
      TRANSPORTS.each do |transport_class|
        begin
          @transport = transport_class.new(self)
          @transport.connect
          if connected?
            return @transport
          end
        rescue
        end
      end
      raise ConnectionFailureError.new "Could not negotiate any transport with server."
    end
  end

  def add_handler(event, &proc)
    @events[event.to_sym] = [] unless @events[event.to_sym]
    @events[event.to_sym] << proc
  end

  def connect_succeeded
    send_packet(HEADER_SYSTEM, ACTION_VERSION_CHECK) { |x| x.ver(:v => CLIENT_VERSION.delete('.')) }
    connect_response = wait_for_packet(CONNECTION_TIMEOUT)
    if connect_response.header == HEADER_SYSTEM and connect_response.action == ACTION_API_OK
      @connected = true
      SmartFox::Logger.info "SmartFox::Client successfully connected with transport #{@transport.inspect}"
      raise_event :connected, self
    else
      raise ApiIncompatibleError if connect_response.action == ACTION_API_OBSOLETE
      raise ConnectionFailureError.new "Did not recieve an expected response from the server."
    end
  end

  private
  def send_packet(header, action, room_id = 0)
    xml = Builder::XmlMarkup.new()
    xml.msg(:t => header) do |msg|
      msg.body(:action => action, :r => room_id) do |body|
        yield body
      end
    end
    packet = xml.target!
    SmartFox::Logger.info "SmartFox::Client#send_packet -> #{packet}"
    @transport.send_data(packet + "\0")
  end

  def wait_for_packet(timeout)
    begin_at = Time.now
    while Time.now <= (begin_at + timeout)
      if @transport.data_available?
        return SmartFox::Packet.parse(@transport.read_packet)
      end
    end

    raise TransportTimeoutError
  end

  def raise_event(event_name, *params)
    event = @events[event_name.to_sym]
    return unless event
    event.each do |event_handler|
      event_handler.call(*params)
    end
  end
end