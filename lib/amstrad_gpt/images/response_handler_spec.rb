# frozen_string_literal: true

require "amstrad_gpt/images/response_handler"
require "amstrad_gpt/amstrad"

RSpec.describe AmstradGpt::Images::ResponseHandler do
  subject { described_class.new(reply:, api_key:) }

  let(:api_key) { "fake-api-key" }
  let(:reply) { '{dalle: "A futuristic city"}' }
  let(:image_processor) { instance_double(AmstradGpt::Images::Processing, apply_downsize_with_dithering: [[0, 0, 0]]) }

  before do
    allow(AmstradGpt::Images::Processing).to receive(:new).and_return(image_processor)
    allow(URI).to receive(:open).and_return(StringIO.new("fake image data"))
    allow(Tempfile).to receive(:new).and_return(double(path: "/tmp/image.png", binmode: nil, write: nil, close: nil,
                                                       unlink: nil))
  end

  describe "#call" do
    it "processes the image and sends it to the Amstrad" do
      allow(AmstradGpt::OpenAiConnection).to receive(:image).and_return("http://example.com/image.png")
      allow(Faraday).to receive(:get).and_return(double(success?: true, body: "fake image data"))
      allow_any_instance_of(AmstradGpt::Images::Processing).to receive(:apply_downsize_with_dithering).and_return([[0, 0, 0]])
      allow_any_instance_of(AmstradGpt::Images::Processing).to receive(:find_closest_amstrad_color).and_return([0, 0, 0])
      allow_any_instance_of(AmstradGpt::Images::Processing).to receive(:find_closest_amstrad_color).and_return([0, 0, 0])

      response = subject.call
      expect(response).to start_with("IMG:")
      decoded = Base64.strict_decode64(response[4..-1])
      expect(decoded).to eq([3, 0].pack("C*"))
    end
  end

  describe "#embellish" do
    it "creates an embellished prompt for DALL-E" do
      embellished = subject.embellish("A futuristic city")
      expect(embellished).to include("Main Theme: A futuristic city")
      expect(embellished).to include("You are a famous artist")
    end
  end

  describe "#generate_image" do
    it "calls OpenAiConnection.image with correct parameters" do
      expect(AmstradGpt::OpenAiConnection).to receive(:image).with(
        api_key: api_key,
        prompt: "A futuristic city",
        size: "1792x1024"
      ).and_return("http://example.com/image.png")

      expect(subject.send(:generate_image, "A futuristic city")).to eq("http://example.com/image.png")
    end
  end

  describe "#encode_image_for_amstrad" do
    it "encodes the processed image for the Amstrad" do
      processed_image = [[0, 0, 0]]
      allow_any_instance_of(AmstradGpt::Images::Processing).to receive(:find_closest_amstrad_color).and_return([0, 0, 0])
      encoded_image = subject.send(:encode_image_for_amstrad, processed_image)
      expect(encoded_image).to be_a(String)
      expect(encoded_image).not_to be_empty
    end
  end
end
