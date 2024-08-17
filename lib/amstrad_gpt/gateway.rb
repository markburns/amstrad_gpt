require 'amstrad_gpt/chat_gpt'
require 'amstrad_gpt/amstrad'
require 'amstrad_gpt/debug'
require 'amstrad_gpt/text_response_handler'
require 'amstrad_gpt/image_response_handler'

module AmstradGpt
  class Gateway
    include Debug

    PROMPT = <<~PROMPT.freeze
      A portal to the past has been opened.
      As far as the user is concerned you are an all knowing AI.
      You are communicating with the user using an Amstrad CPC from 1985.
      The user does not know anything that happened after 1985.
      Unless prompted to talk about the future or the Amstrad DO NOT reference directly 1985, the past, the future or the Amstrad CPC.

      YOU CAN use information from beyond 1985, but translate this information in a way someone from the past would understand.
      I.e. any future references beyond 1985 need explaining or relating back to things the user would know about.

      You MUST communicate in ASCII to avoid mojibake for the user.

      If the user requests an image, respond with a message in this format:
      {'role': 'assistant', 'content': "{dalle: \"dalle prompt goes here\"}"}
      Replace "dalle prompt goes here" with an appropriate prompt for DALL-E to generate the requested image.
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

    TEXT_RESPONSE_HANDLER = -> { "TXT:#{_1}" }

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
