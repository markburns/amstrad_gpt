require 'amstrad_gpt/interface'

module AmstradGpt
  class Amstrad
    def initialize(tty:, base_sleep_duration: 0.1)
      @tty = tty
      @base_sleep_duration = base_sleep_duration
      setup_mutable_state
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

    def send_to_amstrad(message)
      mutex.synchronize do
        interface.write(message)
      end
    end

    def receive_from_amstrad
      start

      new_thread_running_loop do
        message = maybe_message?

        yield message if message.present?

        sleep(base_sleep_duration * rand)
      end
    end

    private

    def interface
      @interface ||= Interface.new(tty:)
    end

    def maybe_message?
      message = nil

      mutex.synchronize do
        if buffer.end_with?("\n\n\n")
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
