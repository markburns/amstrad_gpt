# frozen_string_literal: true

require "amstrad_gpt/interface"
require "amstrad_gpt/amstrad"
require "amstrad_gpt/simulation/socat"
require "amstrad_gpt/simulation/amstrad"

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
  module Simulation
    class ConnectionSimulator
      def initialize(base_sleep_duration: 0.1)
        @base_sleep_duration = base_sleep_duration
      end

      def simulate_message_send(message)
        message = AmstradGpt::Amstrad.delimit(message)

        simulated_amstrad.type(message)
      end

      def setup
        Socat.new(amstrad_simulated_tty:, mac_simulated_tty:).setup

        receive_from_gpt
      end

      def receive_from_gpt
        simulated_amstrad.receive_from_gpt do |content|
          received_messages.push({ role: "assistant", content: })
        end
      end

      def received_messages
        @received_messages ||= []
      end

      def fake_amstrad
        @fake_amstrad ||= AmstradGpt::Amstrad.new(tty: mac_simulated_tty, base_sleep_duration:)
      end

      def mac_simulated_tty = "/tmp/tty.mac_simulated_tty"

      private

      def simulated_amstrad
        @simulated_amstrad ||= Simulation::Amstrad.new(amstrad_simulated_tty:)
      end

      def amstrad_simulated_tty = "/tmp/tty.amstrad_simulated_tty"
      attr_reader :base_sleep_duration
    end
  end
end
