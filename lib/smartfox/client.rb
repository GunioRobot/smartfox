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
  EVENTS = [ :connected, :logged_in ]

  HEADER_SYSTEM = 'sys'
  ACTION_VERSION_CHECK = 'verChk'
  ACTION_API_OK = 'apiOK'
  ACTION_API_OBSOLETE = 'apiKO'
  ACTION_LOGIN = 'login'
  ACTION_LOGIN_OK = 'logOK'
  
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
          started_at = Time.now
          @transport = transport_class.new(self)
          @transport.connect

          while not connected? and Time.now <= started_at + CONNECTION_TIMEOUT
            Thread.pass
          end

          return @transport if connected?
        rescue
        end
      end
      raise ConnectionFailureError.new "Could not negotiate any transport with server."
    end
  end

  def disconnect
    if @connected
      @transport.disconnect
      @connected = false
    end
  end

  def add_handler(event, &proc)
    @events[event.to_sym] = [] unless @events[event.to_sym]
    @events[event.to_sym] << proc
  end

  def connect_succeeded
    send_packet(HEADER_SYSTEM, ACTION_VERSION_CHECK) { |x| x.ver(:v => CLIENT_VERSION.delete('.')) }
  end

  def packet_recieved(data)
    begin
      SmartFox::Logger.debug "SmartFox::Client#packet_recieved('#{data}')"
      packet = SmartFox::Packet.parse(data)
      case packet.header
      when HEADER_SYSTEM
        if @connected
          handle_system_packet(packet)
        else
          complete_login(packet)
        end
      when HEADER_EXTENSION

      end
    rescue => e
      SmartFox::Logger.error "In SmartFox::Client#packet_received"
      SmartFox::Logger.exception e
    end
  end

  def login(zone, username, password = nil)
    send_packet(HEADER_SYSTEM, ACTION_LOGIN) do |packet|
      packet.login(:z => zone) do |login|
        login.nick { |nick| nick.cdata! username }
        login.pword { |pword| pword.cdata! password || '' }
      end
    end
    Thread.pass
  end

  private
  def send_packet(header, action, room_id = 0)
    xml = Builder::XmlMarkup.new()
    xml.msg(:t => header) do |msg|
      msg.body(:r => room_id, :action => action) do |body|
        yield body
      end
    end
    packet = xml.target!
    SmartFox::Logger.info "SmartFox::Client#send_packet -> #{packet}"
    @transport.send_data(packet + "\0")
  end

  def raise_event(event_name, *params)
    event = @events[event_name.to_sym]
    return unless event
    event.each do |event_handler|
      event_handler.call(*params)
    end
  end

  def complete_login(connect_response)
    if connect_response.header == HEADER_SYSTEM and connect_response.action == ACTION_API_OK
      @connected = true
      SmartFox::Logger.info "SmartFox::Client successfully connected with transport #{@transport.inspect}"
      raise_event :connected, self
    else
      raise ApiIncompatibleError if connect_response.action == ACTION_API_OBSOLETE
      raise ConnectionFailureError.new "Did not recieve an expected response from the server."
    end
  end

  def handle_system_packet(packet)
    case packet.action
    when ACTION_LOGIN_OK
      @username = packet.data['n']
      @moderator = packet.data['mod'] != "0"
      @id = packet.data['id']
      SmartFox::Logger.info "SmartFox::Client logged in as #{@username}"
      raise_event(:logged_in, self)
    end
  end
end