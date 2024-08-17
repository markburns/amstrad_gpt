# frozen_string_literal: true

module AmstradGpt
  module Simulation
    class Socat
      def initialize(amstrad_simulated_tty:, mac_simulated_tty:)
        @amstrad_simulated_tty = amstrad_simulated_tty
        @mac_simulated_tty = mac_simulated_tty
      end

      def setup
        puts "====================================="
        socat_install_message unless socat_installed?

        check_and_setup_socat
        puts "====================================="
      end

      def socat_install_message
        puts <<~INSTALL_MESSAGE
        socat not installed, please run:

        brew install socat
        INSTALL_MESSAGE
        exit 1
      end

      def socat_installed?
        system("which socat > /dev/null 2>&1")
      end

      def check_and_setup_socat
        puts "Checking socat configuration..."

        if File.exist?(amstrad_simulated_tty) && File.exist?(mac_simulated_tty)
          puts "socat already configured with #{amstrad_simulated_tty} and #{mac_simulated_tty}"
        else
          setup_socat
        end

        true
      end

      def setup_socat
        require "open3"
        puts "Configuring socat..."

        setup_command = <<~COMMAND
        socat -d -d pty,raw,echo=0, \
          link=#{amstrad_simulated_tty} \
          pty,raw,echo=0, \
          link=#{mac_simulated_tty} &
        COMMAND

        puts setup_command
        system(setup_command)

        puts "socat setup"
      end

      attr_reader :amstrad_simulated_tty, :mac_simulated_tty
    end
  end
end
