require 'amstrad_gpt/amstrad'

RSpec.describe AmstradGpt::Amstrad do
  let(:tty) { '/dev/tty.S0' }
  let(:subject) { described_class.new(tty:, base_sleep_duration:) }
  let(:base_sleep_duration) { 0.0 }

  before do
    allow(Serial).to receive(:new).and_return(serial_port)
  end

  let(:serial_port) do
    instance_double(Serial, write: nil, getbyte: nil, close: nil)
  end

  describe '#initialize' do
    it 'initializes with given tty and sets initial values' do
      expect(subject.instance_variable_get(:@tty)).to eq(tty)
      expect(subject.instance_variable_get(:@buffer)).to eq("")
      expect(subject.instance_variable_get(:@running)).to be true
      expect(subject.instance_variable_get(:@mutex)).to be_a(Mutex)
    end
  end

  describe '#start' do
    it 'starts the reader thread' do
      expect(Thread).to receive(:new).and_call_original
      subject.start
      expect(subject.instance_variable_get(:@reader_thread)).to be_a(Thread)
    end
  end

  describe '#stop' do
    before { subject.start }

    it 'stops the reader thread and closes the serial port' do
      expect(serial_port).to receive(:close)
      subject.stop
      expect(subject.instance_variable_get(:@running)).to be false
      expect(subject.instance_variable_get(:@reader_thread)).to be nil
    end
  end

  describe '#send_to_amstrad' do
    it 'writes a message to the serial port' do
      message = "Hello, Amstrad!"
      expect(serial_port).to receive(:write).with(message)
      subject.send_to_amstrad(message)
    end
  end

  describe '#receive_messages' do
    it 'yields received messages' do
      allow(serial_port).to receive(:getbyte).and_return(
        'a'.ord,
        'b'.ord,
        "\n".ord,
        "\n".ord,
        "\n".ord
      )

      subject.start

      received_messages = []

      subject.receive_messages do |message|
        received_messages << message
      end

      sleep 0.1

      expect(received_messages).to include("ab")
    end
  end
end
