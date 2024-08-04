require 'amstrad_gpt/interface'
require 'amstrad_gpt/amstrad'

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ POST /simulate_amstrad_to_gpt_message ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
#          │
#          │
#          │
#          │                                                                 ┌─────────────┐
#   ┌──────▼─────────┐                                                       │  Gateway    │
#   │                │                                                       └─────────────┘
#   │                │                                                              ▲
#   │   WebServer    │                                                              │
#   │                │ simulate_amstrad_to_gpt_message                              │
#   │                │                  │                                           │
#   └────────────────┘                  │                                   ┌───────▼───────┐
#                                       │                                   │Amstrad (class)│
#                              ┌────────│───────────────────────────────────┤  fake         ├──┐
#                              │        │              ConnectionSimulator     │               │  │
#                              │  ┌─────│───────┐                           │               │  │
#                              │  │ ┌───▼──────┐│                           │               │  │
#                              │  │ │  Socket  ││─┐  ┏━━━━━━━━━━┓           │┌─────────────┐│  │
#                              │  │ └──────────┘│ │  ┃  socat   ┃           ││Mac Simulated││  │
#                              │  │   Amstrad   │ │  ┃          ┃           ││  Interface  ││  │
#                              │  │  Simulated  │ │  ┃  mimics  ┃           ││ ┌──────────┐││  │
#                              │  │  Interface  │ └─▶┃ physical ┃────────────▶ │  Socket  │││  │
#                              │  └─────────────┘    ┃  cable   ┃           ││ └──────────┘││  │
#                              │                     ┃          ┃           │└─────────────┘│  │
#                              │                     ┗━━━━━━━━━━┛           └───────────────┘  │
#                              └───────────────────────────────────────────────────────────────┘
# Web server receives `POST /simulate_amstrad_to_gpt_message`
#  sends a message to the virtual socket amstrad_simulated_tty
#  socat forwards this to the virtual socket mac_simulated_tty
#
#  The mac simulated side has a normal `Amstrad` wrapper class that
#  quacks just like the real Amstrad, so reads the messages in a loop
#  and forwards to the gateway for ordinary processing
module AmstradGpt
  class ConnectionSimulator
    def initialize(base_sleep_duration: 0.1)
      @base_sleep_duration = base_sleep_duration
    end

    def simulate_message_send(message)
      amstrad_simulated_interface.write("#{message}\n\n\n")
    end

    def receive_from_fake_amstrad
      fake_amstrad.received_from_amstrad do |message|
        received_messages << message
      end
    end

    def received_messages
      @received_messages ||= []
    end

    def fake_amstrad
      @fake_amstrad ||= Amstrad.new(tty: mac_simulated_tty, base_sleep_duration:)
    end

    def setup
      socat_install_message unless socat_installed?

      setup_failure_message unless check_and_setup_socat
    end

    def mac_simulated_tty = "/tmp/tty.mac_simulated_tty"

    private

    def amstrad_simulated_interface
      @amstrad_simulated_interface ||= Interface.new(tty: amstrad_simulated_tty)
    end

    def setup_failure_message
      puts "Failed to setup or verify socat configuration"
      exit 2
    end

    def socat_install_message
      puts <<~INSTALL_MESSAGE
        socat not installed, please run:

        brew install socat
      INSTALL_MESSAGE
      exit 1
    end

    def amstrad_simulated_tty = "/tmp/tty.amstrad_simulated_tty"

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
      require 'open3'
      puts "Configuring socat..."
      setup_command = "socat -d -d pty,raw,echo=0,link=#{amstrad_simulated_tty} pty,raw,echo=0,link=#{mac_simulated_tty} &"
      puts setup_command
      system(setup_command)

      puts "socat setup"
    end

    attr_reader :base_sleep_duration
  end
end
