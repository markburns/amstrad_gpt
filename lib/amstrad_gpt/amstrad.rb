# rubocop:todo Style/FrozenStringLiteralComment
# rubocop:enable Style/FrozenStringLiteralComment

require "amstrad_gpt/interface"
require "amstrad_gpt/debug"

module AmstradGpt
  class Amstrad
    include Debug

    AMSTRAD_DELIMITER = "\r\n"
    AMSTRAD_MESSAGE_DELIMITER = AMSTRAD_DELIMITER * 3

    def self.delimit(message)
      return message if message.end_with?(AMSTRAD_MESSAGE_DELIMITER)

      "#{message}#{AMSTRAD_MESSAGE_DELIMITER}"
    end

    def initialize(tty:, base_sleep_duration: 0.1, interface: nil)
      @tty = tty
      @base_sleep_duration = base_sleep_duration
      @interface = interface
      setup_mutable_state
    end

    def name
      "Amstrad.#{tty}"
    end

    def start
      @reader_thread = new_thread_running_loop do
        char = interface.next_character

        mutex.synchronize { buffer << char } if char
        sleep(base_sleep_duration * rand)
      end
    end

    def stop
      @buffer.clear
      @running = false

      @reader_thread.join
      @reader_thread = nil

      interface.shutdown
    end

    def send_to_amstrad(message)
      mutex.synchronize do
        debug("Sending to Amstrad: #{message}")
        message = "#{message}#{AMSTRAD_MESSAGE_DELIMITER}" unless message.end_with?(AMSTRAD_MESSAGE_DELIMITER)
        interface.write(message)
      end
    end

    def receive_from_amstrad
      start

      Thread.new do
        while @running
          message = maybe_message?

          if message.present?
            debug("Received from Amstrad: #{message}")
            yield message
          end

          sleep(base_sleep_duration * rand)
        end
      end
    end

    private

    def interface
      @interface ||= Interface.new(tty:)
    end

    def maybe_message?
      message = nil

      mutex.synchronize do
        if buffer.end_with?(AMSTRAD_MESSAGE_DELIMITER)
          message = buffer[0..-4].strip
          buffer.clear
        end
      end

      message
    end

    def setup_mutable_state
      @mutex = Mutex.new
      @buffer = ""
      @running = true
    end

    def new_thread_running_loop
      Thread.new do
        yield while @running
      end
    end

    attr_reader :tty, :mutex, :base_sleep_duration, :buffer
  end
end
