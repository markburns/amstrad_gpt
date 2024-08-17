# frozen_string_literal: true

require "faraday"
require "json"

module AmstradGpt
  class ChatGpt
    def initialize(api_key:, prompt:)
      @api_key = api_key
      @prompt = prompt
    end

    def send_message(content)
      append({ role: "user", content: })

      response = post
      parse_response(response.body)
    end

    def messages
      @messages ||= []
    end

    private

    def post
      connection.post do |req|
        req.body = {
          model: "gpt-4o",
          messages: [system, *messages]
        }.to_json
      end
    end

    def system
      { role: "system", content: prompt }
    end

    def connection
      @connection ||= Faraday.new(
        url: "https://api.openai.com/v1/chat/completions",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{api_key}"
        }
      ) do |faraday|
        faraday.adapter Faraday.default_adapter
      end
    end

    def parse_response(response_body)
      choices = JSON.parse(response_body)["choices"]

      message = choices.first["message"]
      append message.tap { _1[:role] = "assistant" }
      message[:content]
    end

    def append(message)
      messages.push message.transform_keys!(&:to_sym)
    end

    attr_reader :api_key, :prompt
  end
end
