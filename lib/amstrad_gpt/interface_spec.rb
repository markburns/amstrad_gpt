require_relative './interface'

RSpec.describe AmstradGpt::Interface do
  subject do
    AmstradGpt::Interface.new(tty:)
  end

  let(:tty) { '/dev/ttyS0' }
  let(:serial_port_double) { instance_double(Serial) }

  before do
    allow(Serial).to receive(:new).and_return(serial_port_double)
    allow(serial_port_double).to receive(:close)
    allow(serial_port_double).to receive(:getbyte)
    allow(serial_port_double).to receive(:write)
  end

  describe '#initialize' do
    it 'initializes with a tty device' do
      expect(subject.instance_variable_get(:@tty)).to eq(tty)
    end
  end

  describe '#shutdown' do
    it 'closes the serial port' do
      subject.shutdown
      expect(serial_port_double).to have_received(:close)
    end
  end

  describe '#write' do
    it 'delegates write to the serial port' do
      subject.write('test message')
      expect(serial_port_double).to have_received(:write).with('test message')
    end
  end

  describe '#next_character' do
    it 'returns the next character from the serial port' do
      allow(serial_port_double).to receive(:getbyte).and_return('a'.ord)
      expect(subject.next_character).to eq('a'.ord)
    end

    it 'returns nil if getbyte raises an error' do
      allow(serial_port_double).to receive(:getbyte).and_raise(StandardError)
      expect(subject.next_character).to be_nil
    end
  end

  describe 'serial port initialization' do
    it 'creates a serial port with correct parameters' do
      subject.shutdown # any method with side effects that indirectly instantiates the serial port

      expect(Serial).to have_received(:new).with(tty, 9600, 8, :none, 1)
    end
  end
end
