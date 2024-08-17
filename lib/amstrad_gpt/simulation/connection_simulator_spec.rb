# frozen_string_literal: true

require_relative "./connection_simulator"

RSpec.describe AmstradGpt::Simulation::ConnectionSimulator do
  subject do
    described_class.new(base_sleep_duration:)
  end

  let(:amstrad_simulated_tty) { "/tmp/tty.amstrad_simulated_tty" }
  let(:mac_simulated_tty) { "/tmp/tty.mac_simulated_tty" }
  let(:base_sleep_duration) { 0.01 }
  let(:interface_double) { instance_double(AmstradGpt::Interface) }
  let(:amstrad_double) { instance_double(AmstradGpt::Amstrad) }

  before do
    allow(AmstradGpt::Interface).to receive(:new).and_return(interface_double)
    allow(interface_double).to receive(:write)

    allow(AmstradGpt::Amstrad).to receive(:new).and_return(amstrad_double)
  end

  describe "#simulate_message_send" do
    it "sends a formatted message through the simulated interface" do
      message = "Hello, GPT!"
      expect_any_instance_of(AmstradGpt::Simulation::Amstrad).to receive(:type).with(AmstradGpt::Amstrad.delimit(message))
      subject.simulate_message_send(message)
    end
  end

  describe "#fake_amstrad" do
    it "returns a memoized instance of Amstrad initialized with the mac simulated tty" do
      expect(AmstradGpt::Amstrad)
        .to receive(:new)
        .with(
          tty: mac_simulated_tty,
          base_sleep_duration:
        )
        .once
        .and_return(amstrad_double)

      2.times { subject.fake_amstrad }
    end
  end
end
