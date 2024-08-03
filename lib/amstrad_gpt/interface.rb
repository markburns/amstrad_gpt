require 'rubyserial'

module AmstradGpt
  class Interface
    def initialize(tty:)
      @tty = tty
    end

    def shutdown
      serial_port.close
    end

    delegate :write, to: :serial_port

    def next_character
      serial_port.getbyte rescue nil
    end

    private

    def serial_port
      @serial_port ||= Serial.new(@tty, baud_rate, data_bits, stop_bits, parity)
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
  end
end
