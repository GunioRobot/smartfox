class SmartFox::Room
  attr_reader :id, :name, :private, :temporary, :game, :max_users, :users, :transcript

  EVENTS = [ :message_sent, :message_received, :message_received_self, :message_received_other, :user_joined, :user_left, :user_count_updated ]
  ACTION_PUBLISH_MESSAGE = 'pubMsg'
  ACTION_USER_ENTER = 'uER'
  ACTION_UPDATE_USER_COUNT = 'uCount'

  def initialize(client, node)
    @client = client
    @id = node['id'].to_i
    @name = node.first.content
    @private = node['priv'] == '1'
    @temporary = node['temp'] == '1'
    @current_users = node['ucnt'].to_i
    @max_users = node['maxu'].to_i
    @game = node['game'] == '1'
    @events = {}
    @transcript = []

    @users = nil
    SmartFox::Logger.debug "SmartFox::Room.new -> #{inspect}"
  end

  def current_users
    @users ? @users.length : @current_users
  end

  def self.parse(client, node)
    new(client, node)
  end

  def inspect
    "#<#{self.class.name}:#{object_id} id:#{@id} name:#{@name}#{' temporary' if @temporary}#{' private' if @private} current_users:#{@current_users} max_users:#{@max_users}>"
  end

  def join
    @client.join_room self
  end

  def joined
    @transcript.clear
  end

  def parse_users(users)
    @users = {}

    users.children.each do |child|
      user = @client.parse_user(child)
      @users[user.id] = user
    end
  end
  
  def send_message(message)
    SmartFox::Logger.info "SmartFox::Room#send_message('#{message}')"
    @client.send :send_packet, SmartFox::Client::HEADER_SYSTEM, ACTION_PUBLISH_MESSAGE, self.id do |packet|
      packet.txt do |txt|
        txt.cdata! message
      end
    end

    @transcript << SmartFox::Message.new(@client.users[@client.user_id], message, self)

    raise_event :message_sent, @client, self, message
  end

  def handle_system_packet(packet)
    case packet.action
    when ACTION_PUBLISH_MESSAGE
      text = packet.data.find{|c| c.name == 'txt'}.child.content
      user_id = packet.data.find{|c| c.name == 'user'}['id'].to_i
      user = @client.users[user_id]
      message = SmartFox::Message.new(user, text, self)
      SmartFox::Logger.info "SmartFox::Room did receive message #{message.inspect}"
      @transcript << message unless user.id == @client.user_id

      SmartFox::Logger.info "SmartFox::Room#handle_system_packet ACTION_PUBLISH_MESSAGE #{user.id} == #{@client.user_id}"
      if user.id == @client.user_id
        SmartFox::Logger.debug "SmartFox::Room#handle_system_packet ACTION_PUBLISH_MESSAGE from self"
        raise_event :message_received_self, @client, @room, message
      else
        SmartFox::Logger.debug "SmartFox::Room#handle_system_packet ACTION_PUBLISH_MESSAGE from #{user.name}"
        raise_event :message_received_other, @client, @room, message
      end
      raise_event :message_received, @client, @room, message
    when ACTION_USER_ENTER
      packet.data.each do |u|
        user = @client.parse_user(u)
        @users[user.id] = user
        raise_event :user_joined, @client, self, user
      end
    when ACTION_UPDATE_USER_COUNT
      old_count = @current_users
      @current_users = packet.body['u'].to_i
      raise_event :user_count_updated, @client, self, { :old => old_count, :new => @current_users }
    end
  end

  def add_handler(event, &proc)
    @events[event.to_sym] = [] unless @events[event.to_sym]
    @events[event.to_sym] << proc
  end

  private
  def raise_event(event_name, *params)
    event = @events[event_name.to_sym]
    return unless event
    event.each do |event_handler|
      event_handler.call(*params)
    end

    # Pass the message upstream to the client as well
    @client.send :raise_event, event_name, self, *params
  end
end