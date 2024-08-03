require 'sinatra/base'
require 'json'

module AmstradGpt
  class WebServer < Sinatra::Base
    cattr_accessor :gateway

    set :port, 4567
    set :environment, :production

    post '/send_message' do
      gateway.send_message(params[:message])
    end

    get '/' do
      gateway.messages.map do |message|
        "#{message[:role]}: #{message[:content]}"
      end.join("<br/>")
    end

    def gateway
      self.class.gateway
    end
  end
end
