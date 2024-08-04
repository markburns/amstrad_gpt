require 'amstrad_gpt/gateway'

RSpec.describe AmstradGpt::Gateway do
  subject { described_class.new(api_key:, amstrad:) }

  let(:api_key) { 'fake_api_key' }
  let(:tty) { '/dev/ttyS0' }
  let(:amstrad) { instance_double(AmstradGpt::Amstrad, receive_from_amstrad: nil, send_to_amstrad: nil, tty:) }
  let(:chat_gpt) { instance_double(AmstradGpt::ChatGpt, send_message: 'response_message') }

  before do
    allow(AmstradGpt::Amstrad).to receive(:new).and_return(amstrad)
    allow(AmstradGpt::ChatGpt).to receive(:new).and_return(chat_gpt)
  end

  describe '.run' do
    it 'creates a new instance and calls run on it' do
      expect(described_class).to receive(:new).with(api_key: api_key, tty: tty).and_return(subject)
      expect(subject).to receive(:run)
      described_class.run(api_key: api_key, tty: tty)
    end
  end

  describe '#initialize' do
    it 'initializes with given api_key and tty' do
      expect(subject.instance_variable_get(:@api_key)).to eq(api_key)
      expect(subject.instance_variable_get(:@amstrad)).to eq(amstrad)
    end
  end

  describe '#run' do
    it 'starts receiving messages from the Amstrad' do
      expect(amstrad).to receive(:receive_from_amstrad)
      subject.run
    end
  end

  describe '#forward' do
    it 'sends the message to ChatGpt and replies with the response' do
      message = 'test_message'
      expect(chat_gpt).to receive(:send_message).with(message).and_return('response_message')
      expect(amstrad).to receive(:send_to_amstrad).with('response_message')
      subject.send(:forward, message)
    end
  end

  describe '#amstrad' do
    it 'initializes Amstrad instance with tty' do
      expect(subject.send(:amstrad)).to eq(amstrad)
    end
  end

  describe '#chat_gpt' do
    it 'initializes ChatGpt instance with api_key and prompt' do
      expect(AmstradGpt::ChatGpt).to receive(:new).with(api_key: api_key, prompt: described_class::PROMPT).and_return(chat_gpt)
      expect(subject.send(:chat_gpt)).to eq(chat_gpt)
    end
  end
end
