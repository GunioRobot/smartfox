class SmartFox::Message
  attr_accessor :user, :message, :room

  def initialize(user, message, room)
    @user, @message, @room = user, message, room
  end
end