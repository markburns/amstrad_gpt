require 'active_support/all'
require_relative "amstrad_gpt/version"

module AmstradGpt
  def self.run(...)
    require 'amstrad_gpt/gateway'

    gateway = Gateway.run(...)
    puts "AmstradGpt Gateway started on #{gateway.tty}"

    require 'amstrad_gpt/web_server'
    AmstradGpt::WebServer.gateway = gateway
    AmstradGpt::WebServer.run!
  end
end
