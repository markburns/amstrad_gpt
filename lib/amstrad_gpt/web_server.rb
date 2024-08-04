require 'sinatra/base'
require 'json'

module AmstradGpt
  class WebServer < Sinatra::Base
    cattr_accessor :gateway, :simulator
    delegate :gateway, :simulator, to: :class

    set :port, 4567
    set :environment, :production

    post '/send_message' do
      gateway.send_message(params[:message])
    end

    post '/simulate_send_message' do
      next 'No simulator running' if simulator.nil?

      simulator.simulate_message_send(params[:message])
      "Message sent"
    end

    get '/' do
      gateway.messages.map do |message|
        "#{message[:role]}: #{message[:content]}"
      end.join("<br/>")
    end
  end
end
