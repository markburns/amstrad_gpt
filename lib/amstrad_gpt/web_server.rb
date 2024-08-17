# frozen_string_literal: true

require "sinatra/base"
require "json"

module AmstradGpt
  class WebServer < Sinatra::Base
    cattr_accessor :gateway, :simulator
    delegate :gateway, :simulator, to: :class

    set :port, 4567
    set :environment, :production

    post "/send_message" do
      gateway.send_message(params[:message])
    end

    post "/simulate_send_message" do
      next "No simulator running" if simulator.nil?

      simulator.simulate_message_send(params[:message])

      "Message sent\n"
    end

    get "/simulated_messages" do
      list simulator.received_messages
    end

    get "/messages" do
      list gateway.messages
    end

    post "/send_to_amstrad" do
      puts gateway.send_to_amstrad(params[:message])
    end

    private

    def list(messages)
      "<ul>#{messages_list(messages)}</ul>"
    end

    def messages_list(messages)
      messages.map do |message|
        "<li>#{message[:role]}: #{message[:content]}</li>"
      end.join("\n")
    end
  end
end
