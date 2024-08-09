require 'amstrad_gpt/image_response_handler'
require 'amstrad_gpt/amstrad'

RSpec.describe AmstradGpt::ImageResponseHandler do
  subject { described_class.new(reply:, amstrad:, api_key:) }

  let(:api_key) { 'fake-api-key' }
  let(:reply) { '{dalle: "A futuristic city"}' }
  let(:amstrad) { instance_double(AmstradGpt::Amstrad, send_to_amstrad: nil) }
  let(:image_processor) { instance_double(AmstradGpt::ImageProcessing, apply_downsize_with_dithering: [[0, 0, 0]]) }

  before do
    allow(AmstradGpt::ImageProcessing).to receive(:new).and_return(image_processor)
    allow(URI).to receive(:open).and_return(StringIO.new("fake image data"))
    allow(Tempfile).to receive(:new).and_return(double(path: '/tmp/image.png', binmode: nil, write: nil, close: nil, unlink: nil))
  end

  describe '#process_and_send' do
    it 'processes the image and sends it to the Amstrad' do
      expect(subject).to receive(:generate_image).and_return("http://example.com/image.png")
      expect(subject).to receive(:process_image).and_call_original
      expect(subject).to receive(:encode_image_for_amstrad).and_return("encoded_image_data")
      expect(amstrad).to receive(:send_to_amstrad).with("IMG:encoded_image_data")

      subject.process_and_send
    end
  end

  describe '#extract_dalle_prompt' do
    it 'extracts the DALL-E prompt from the reply' do
      expect(subject.send(:extract_dalle_prompt, reply)).to eq("A futuristic city")
    end
  end

  describe '#generate_image' do
    before do
      expect(AmstradGpt::OpenAiConnection).to receive(:post).with(
        url: 'https://api.openai.com/v1/images/generations',
        api_key:,
        body: { 
          prompt: "A futuristic city" ,
          n: 1,
          size: "512x512",
          response_format: "url"
        },
      ).and_return({ data: [{url: }] }.with_indifferent_access)
    end

    let(:url) do
      "https://via.placeholder.com/512x512"
    end

    it 'returns a placeholder image URL' do
      expect(subject.send(:generate_image, "A futuristic city"))
        .to eq(url)
    end
  end

  describe '#encode_image_for_amstrad' do
    it 'encodes the processed image for the Amstrad' do
      processed_image = [[0, 0, 0]]
      encoded_image = subject.send(:encode_image_for_amstrad, processed_image)
      expect(encoded_image).to be_a(String)
      expect(encoded_image).not_to be_empty
    end
  end
end
