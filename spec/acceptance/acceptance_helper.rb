require_relative "../spec_helper"
require "steak"

require_relative 'support/database'
require_relative 'support/app'
require_relative 'support/facebookable'
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/pages/**/*.rb"].each {|f| require f}

WebMock.allow_net_connect!
Capybara.default_wait_time = 10
