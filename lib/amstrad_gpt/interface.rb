# frozen_string_literal: true

require "rubyserial"
require "amstrad_gpt/debug"

module AmstradGpt
  class Interface
    include Debug

    def initialize(tty:)
      @tty = tty
    end

    def name
      "Interface.#{tty}"
    end

    def shutdown
      serial_port.close
    end

    def write(message)
      debug("Writing message: #{message}")

      message.each_char do |c|
        debug("Sending char: #{c.inspect}")

        sleep(0.02) # sleep for 1/50th of a second (20ms)
        serial_port.write(c)
      end
    end

    def next_character
      serial_port.getbyte.tap do |c|
        debug("Received char: #{c}") if c
      end
    rescue StandardError => e
      puts e
    end

    private

    def serial_port
      @serial_port ||= Serial.new(@tty, baud_rate, data_bits, parity, stop_bits)
    end

    def baud_rate
      9600
    end

    def data_bits
      8
    end

    def stop_bits
      1
    end

    def parity
      :none
    end

    attr_reader :tty
  end
end
