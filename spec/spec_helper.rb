$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'smartfox'
require 'spec'
require 'spec/autorun'

require File.join(File.dirname(__FILE__), 'waiter')

SmartFox::Logger.level = Logger::DEBUG

Spec::Runner.configure do |config|
  
end
