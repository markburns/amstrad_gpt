module AmstradGpt
  class SimulatedAmstrad
    def initialize(base_sleep_duration: 0.1, amstrad_simulated_tty:)
      @base_sleep_duration = base_sleep_duration
      @amstrad_simulated_tty = amstrad_simulated_tty

      setup_mutable_state
    end

    def simulate_message_send(message)
      amstrad_simulated_interface.write("#{message}\n\n\n")
    end

    def received_messages
      @received_messages ||= []
    end

    private

    attr_reader :base_sleep_duration, :amstrad_simulated_tty

    def start
      @reader_thread = new_thread_running_loop do
        char = amstrad_simulated_interface.next_character

        mutex.synchronize { buffer << char } if char

        sleep(base_sleep_duration * rand)
      end
    end

    def stop
      @running = false

      @reader_thread.join
      @reader_thread = nil

      amstrad_simulated_interface.shutdown
    end

    def send_to_gpt(message)
      mutex.synchronize do
        amstrad_simulated_interface.write(message)
      end
    end

    def receive_from_gpt
      start

      new_thread_running_loop do
        message = maybe_message?

        yield message if message.present?

        sleep(base_sleep_duration * rand)
      end
    end

    private

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

    def amstrad_simulated_interface
      @amstrad_simulated_interface ||= Interface.new(tty: amstrad_simulated_tty)
    end


    attr_reader :tty, :mutex, :base_sleep_duration, :buffer
  end
end
