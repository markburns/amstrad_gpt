# frozen_string_literal: true

require "active_support/all"
require_relative "amstrad_gpt/version"

module AmstradGpt
  class << self
    def run(tty:, api_key:)
      require "amstrad_gpt/amstrad"
      start_gateway(tty:, amstrad: Amstrad.new(tty:), api_key:)
      puts "====================================="
      web_server.join
    end

    def run_simulation(api_key:)
      require "amstrad_gpt/connection_simulator"

      simulator = AmstradGpt::ConnectionSimulator.new
      simulator.setup

      start_gateway(tty: simulator.mac_simulated_tty,
                    amstrad: simulator.fake_amstrad,
                    api_key:,
                    simulator:)
    end

    def reset!
      require "amstrad_gpt/web_server"
      WebServer.reset!
      resettable_objects.each(&:reset!)
      @resettable_objects = nil
    end

    def register(resettable:)
      if resettable.respond_to?(:reset!) && !resettable.is_a?(InstanceDouble)
        resettable_objects.push(resettable)
      end
    end

    private

    def resettable?(resettable:)
      return unless resettable.respond_to?(:reset!)

      return if defined?(InstanceDouble) && resettable.is_a?(InstanceDouble)

      true
    end
      if resettable.respond_to?(:reset!) && !resettable.is_a?(InstanceDouble)
    def resettable_objects
      @resettable_objects ||= []
    end

    def start_gateway(tty:, amstrad:, api_key:, simulator: nil)
      require "amstrad_gpt/gateway"
      gateway = Gateway.run(amstrad:, api_key:)
      puts "AmstradGpt Gateway started on #{tty}"
      puts "====================================="

      require "amstrad_gpt/web_server"
      AmstradGpt::WebServer.gateway = gateway
      AmstradGpt::WebServer.simulator = simulator
      AmstradGpt::WebServer.run!
    end
  end
end
