# frozen_string_literal: true

require "amstrad_gpt/debug"

module AmstradGpt
  class SimulatedAmstrad
    include Debug

    def initialize(amstrad_simulated_tty:, base_sleep_duration: 0.1)
      @base_sleep_duration = base_sleep_duration
      @amstrad_simulated_tty = amstrad_simulated_tty

      setup_mutable_state
    end

    def type(message)
      interface.write(message)
    end

    def start
      @reader_thread = new_thread_running_loop do
        char = interface.next_character

        mutex.synchronize { buffer << char } if char

        sleep(base_sleep_duration * rand)
      end
    end

    def stop
      @running = false

      @reader_thread.join
      @reader_thread = nil

      interface.shutdown
    end

    def send_to_gpt(message)
      mutex.synchronize do
        interface.write(message)
      end
    end

    def receive_from_gpt
      start

      debug "started"

      new_thread_running_loop do
        message = maybe_message?

        if message.present?
          debug message
          yield message
        end

        sleep(base_sleep_duration * rand)
      end
    end

    private

    def name
      self.class.name
    end

    attr_reader :base_sleep_duration, :amstrad_simulated_tty, :tty, :mutex, :buffer

    def maybe_message?
      message = nil

      mutex.synchronize do
        puts buffer if buffer.length.positive?

        if buffer.end_with?(Amstrad::AMSTRAD_MESSAGE_DELIMITER)
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

    def interface
      @interface ||= Interface.new(tty: amstrad_simulated_tty)
    end
  end
end
