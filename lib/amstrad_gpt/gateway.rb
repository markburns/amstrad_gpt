require 'amstrad_gpt/chat_gpt'
require 'amstrad_gpt/amstrad'
require 'amstrad_gpt/debug'

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
    PROMPT

    def self.run(...)
      new(...).tap(&:run)
    end

    def initialize(api_key:, amstrad:)
      @api_key = api_key
      @amstrad = amstrad
    end

    def name
      'Gateway'
    end

    def run
      amstrad.receive_from_amstrad do |message|
        forward(message)
      end
    end

    delegate :send_message, :messages, to: :chat_gpt

    private

    def forward(message)
      debug "Forwarding message: #{message}"

      reply = chat_gpt.send_message(message)

      debug "Received reply from ChatGPT: #{reply}"

      debug "Sending to Amstrad: #{reply}"

      amstrad.send_to_amstrad(reply)
      debug "Sent to Amstrad: #{reply}"
    end

    def chat_gpt
      @chat_gpt ||= ChatGpt.new(api_key:, prompt: PROMPT)
    end

    attr_reader :api_key, :amstrad
  end
end
