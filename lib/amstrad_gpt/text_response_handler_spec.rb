require 'amstrad_gpt/text_response_handler'

RSpec.describe AmstradGpt::TextResponseHandler do
  subject { described_class.new(reply: reply, amstrad: amstrad) }

  let(:reply) { 'This is a test message.' }
  let(:amstrad) { instance_double(AmstradGpt::Amstrad, send_to_amstrad: nil) }

  describe '#process_and_send' do
    it 'sends the text message to the Amstrad' do
      expect(amstrad).to receive(:send_to_amstrad).with("TXT#{reply}")
      subject.process_and_send
    end
  end
end
