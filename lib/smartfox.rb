require 'rubygems'
require 'logger'

module SmartFox
  class SmartFoxError < Exception; end
  
  autoload :Client, 'smartfox/client'
  autoload :Socket, 'smartfox/socket'
  autoload :BlueBox, 'smartfox/blue_box'
  autoload :Packet, 'smartfox/packet'
  
  Logger = Logger.new(STDOUT)
end
