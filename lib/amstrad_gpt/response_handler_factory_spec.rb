require 'amstrad_gpt/response_handler_factory'
require 'amstrad_gpt/text_response_handler'
require 'amstrad_gpt/image_response_handler'

RSpec.describe AmstradGpt::ResponseHandlerFactory do
  subject { described_class.new(amstrad: amstrad) }

  let(:amstrad) { instance_double(AmstradGpt::Amstrad) }

  describe '#create_handler' do
    context 'when the reply contains a DALL-E prompt' do
      let(:reply) { '{dalle: "A futuristic city"}' }

      it 'returns an ImageResponseHandler' do
        handler = subject.create_handler(reply)
        expect(handler).to be_a(AmstradGpt::ImageResponseHandler)
      end
    end

    context 'when the reply is a regular text message' do
      let(:reply) { 'This is a regular text message.' }

      it 'returns a TextResponseHandler' do
        handler = subject.create_handler(reply)
        expect(handler).to be_a(AmstradGpt::TextResponseHandler)
      end
    end
  end
end
