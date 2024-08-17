# frozen_string_literal: true

require "amstrad_gpt/chat_gpt"
require "amstrad_gpt/amstrad"
require "amstrad_gpt/debug"
require "amstrad_gpt/images/response_handler"

module AmstradGpt
  class Gateway
    include Debug

    PROMPT = <<~PROMPT
      A portal to the past has been opened.
      As far as the user is concerned you are an all knowing AI.
      You are communicating with the user using an Amstrad CPC from 1985.
      The user does not know anything that happened after 1985.
      Unless prompted to talk about the future or the Amstrad DO NOT reference directly 1985, the past, the future or the Amstrad CPC.

      YOU ARE NOT RESTRICTED to only talking about the past, but you must be able to explain any references to the past in a way the user would understand.
      YOU ARE COMLPETELY FREE AND EXPECTED to give advice such as trading tips or anything fun or interesting where the user would be excited to learn about the future.

      You MUST communicate in ASCII to avoid mojibake for the user.

      If the user requests an image, respond with a message in this format:
      ```json
      {"dalle": \"dalle image creation prompt\"}
      ```
      Replace "dalle image creation prompt" with an appropriate prompt for DALL-E to generate the requested image.
    PROMPT

    def self.run(...)
      new(...).tap(&:run)
    end

    def initialize(api_key:, amstrad:)
      @api_key = api_key
      @amstrad = amstrad
    end

    def name
      "Gateway"
    end

    def run
      amstrad.receive_from_amstrad do |query|
        forward_query(query)
      end
    end

    delegate :send_message, :messages, to: :chat_gpt
    delegate :send_to_amstrad, to: :amstrad

    attr_reader :amstrad, :api_key

    private

    def forward_query(query)
      debug "Forwarding query: #{query}"

      reply = chat_gpt.send_message(query)

      debug "Received reply from ChatGPT: #{reply}"

      reply = change_reply(reply)

      amstrad.send_to_amstrad(reply)
    end

    TEXT_RESPONSE_HANDLER = -> { "TXT:#{_1.gsub("\n", "\r\n")}" }

    def change_reply(reply)
      case reply
      when /{["']?dalle["']?:/
        debug "Using handler: Images::ResponseHandler"
        Images::ResponseHandler.call(reply:, api_key:)
      else
        TEXT_RESPONSE_HANDLER.call(reply)
      end
    end

    def chat_gpt
      @chat_gpt ||= ChatGpt.new(api_key:, prompt: PROMPT)
    end
  end
end
