require 'rubygems'
require 'logger'

module SmartFox
  class SmartFoxError < Exception; end
  
  autoload :Client, 'smartfox/client'
  autoload :Socket, 'smartfox/socket'
  autoload :BlueBox, 'smartfox/blue_box'
  autoload :Packet, 'smartfox/packet'
  
  Logger = Logger.new(STDOUT)

  class << Logger
    def exception(exception)
      error exception.message
      exception.backtrace.each do |line|
        error "  #{line}"
      end
    end
  end
end
