require 'amstrad_gpt/chat_gpt'
require 'amstrad_gpt/amstrad'

module AmstradGpt
  class Gateway
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

    attr_reader :tty

    def initialize(api_key:, tty:)
      @api_key = api_key
      @tty = tty
    end

    def run
      amstrad.receive_messages do |message|
        handle(message)
      end
    end

    delegate :send_message, :messages, to: :chat_gpt

    private

    def handle(message)
      puts message

      message = chat_gpt.send_message(message)

      amstrad.reply(message)
    end

    def amstrad
      @amstrad ||= Amstrad.new(tty:)
    end

    def chat_gpt
      @chat_gpt ||= ChatGpt.new(api_key:, prompt: PROMPT)
    end

    attr_reader :api_key
  end
end
