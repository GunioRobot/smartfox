require 'socket'

class SmartFox::Socket::Connection
  DEFAULT_PORT = 9339
  attr_reader :connected
  alias_method :connected?, :connected

  def initialize(client)
    @client = client
    @connected = false
    @event_thread = nil
    @disconnecting = false
    @buffer = String.new
  end

  def connect
    begin
      SmartFox::Logger.info "SmartFox::Socket::Connection#connect began"
      @socket = TCPSocket.new(@client.server, @client.port || DEFAULT_PORT)
      # SmartFox sockets will send a cross domain policy, receive this packet
      #  before we do anything else or the connection will hang
      @socket.readpartial(4096)
      @connected = true
      @event_thread = Thread.start(self) { |connection| connection.event_loop }
      @client.connect_succeeded
      
    rescue => e
      SmartFox::Logger.error "In SmartFox::Socket::Connection#connect:"
      SmartFox::Logger.error "  #{e.inspect}"
    end
  end

  def disconnect
    @disconnecting = true
    while @connected
      sleep
    end
  end

  def send_data(data)
    @socket.write(data)
  end

  def data_available?
    not @buffer.empty?
  end

  def read_packet
    packet = @buffer
    @buffer = ""
    return packet
  end

  def event_loop
    SmartFox::Logger.info "SmartFox::Socket::Connection#event_loop began"
    ticks = 0
    until @disconnecting
      SmartFox::Logger.debug "SmartFox::Socket::Connection#event_loop tick #{ticks}"

      @buffer << @socket.readpartial(4096)

      ticks += 1
    end

    @connected = false
  end

  def inspect
    "#<#{self.class.name}:#{object_id} server:#{@client.server} port:#{@client.port || DEFAULT_PORT}>"
  end
end