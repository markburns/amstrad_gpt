# frozen_string_literal: true

require "amstrad_gpt/amstrad"

RSpec.describe AmstradGpt::Amstrad do
  let(:tty) { "/dev/tty.S0" }
  let(:interface) { instance_double(AmstradGpt::Interface) }
  let(:subject) { described_class.new(tty:, base_sleep_duration:, interface:) }
  let(:base_sleep_duration) { 0.0 }

  before do
    allow(interface).to receive(:next_character)
    allow(interface).to receive(:write)
    allow(interface).to receive(:shutdown)
  end

  describe "#initialize" do
    it "initializes with given tty and sets initial values" do
      expect(subject.instance_variable_get(:@tty)).to eq(tty)
      expect(subject.instance_variable_get(:@buffer)).to eq("")
      expect(subject.instance_variable_get(:@running)).to be true
      expect(subject.instance_variable_get(:@mutex)).to be_a(Mutex)
    end
  end

  describe "#start" do
    it "starts the reader thread" do
      expect(Thread).to receive(:new).and_call_original
      subject.start
      expect(subject.instance_variable_get(:@reader_thread)).to be_a(Thread)
    end
  end

  describe "#stop" do
    before { subject.start }

    it "stops the reader thread and shuts down the interface" do
      expect(interface).to receive(:shutdown)
      subject.stop
      expect(subject.instance_variable_get(:@running)).to be false
      expect(subject.instance_variable_get(:@reader_thread)).to be nil
    end
  end

  describe "#send_to_amstrad" do
    it "writes a message to the serial port" do
      message = "Hello, Amstrad!"
      expect(subject.send(:interface)).to receive(:write).with("#{message}#{described_class::AMSTRAD_MESSAGE_DELIMITER}")
      subject.send_to_amstrad(message)
    end
  end

  describe "#receive_from_amstrad" do
    let(:base_sleep_duration) { 0.01 }

    it "yields received messages" do
      allow(interface).to receive(:next_character).and_return(
        "a".ord,
        "b".ord,
        "\r".ord,
        "\n".ord,
        "\r".ord,
        "\n".ord,
        "\r".ord,
        "\n".ord,
        nil
      )

      received_messages = []
      thread = subject.receive_from_amstrad do |message|
        received_messages << message
      end

      # Wait for the thread to process the message
      sleep base_sleep_duration * 10

      # Stop the thread
      subject.stop

      # Wait for the thread to finish
      thread.join

      expect(received_messages).to eq(["ab"])
    end
  end
end
