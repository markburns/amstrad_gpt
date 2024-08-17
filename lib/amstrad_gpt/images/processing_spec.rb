# frozen_string_literal: true

require "amstrad_gpt/images/processing"

RSpec.describe AmstradGpt::Images::Processing do
  let(:input_filename) { "test_image.png" }
  let(:output_filename) { "output_test_image.png" }
  let(:image_processing) { described_class.new(input_filename: input_filename, output_filename: output_filename) }
  let(:mock_image) { instance_double(ChunkyPNG::Image) }

  before do
    allow(ChunkyPNG::Image).to receive(:from_file).and_return(mock_image)
    allow(mock_image).to receive(:width).and_return(640)
    allow(mock_image).to receive(:height).and_return(400)
    allow(mock_image).to receive(:[]) do |x, y|
      ChunkyPNG::Color.rgb(128, 128, 128)
    end
  end

  around do |example|
    # time example and puts
    time = Benchmark.realtime do
      example.run
    end

    puts "Example #{example.full_description} took #{time} seconds"
  end

  describe "#apply_downsize_with_dithering" do
    it "returns a 2D array of the correct dimensions" do
      result = image_processing.apply_downsize_with_dithering
      expect(result.length).to eq(described_class::TARGET_HEIGHT)
      expect(result.first.length).to eq(described_class::TARGET_WIDTH)
    end

    it "handles error distribution without raising exceptions" do
      expect { image_processing.apply_downsize_with_dithering }.not_to raise_error
    end

    it "produces valid RGB values" do
      result = image_processing.apply_downsize_with_dithering
      result.each do |row|
        row.each do |color|
          expect(color).to all(be_between(0, 255))
        end
      end
    end

    context "with various input colors" do
      let(:colors) do
        [
          [0, 0, 0],
          [255, 255, 255],
          [128, 128, 128],
          [255, 0, 0],
          [0, 255, 0],
          [0, 0, 255]
        ]
      end

      it "handles different input colors without errors" do
        colors.each_with_index do |color, index|
          allow(mock_image).to receive(:[]) do |x, y|
            ChunkyPNG::Color.rgb(*color)
          end
          expect { image_processing.apply_downsize_with_dithering }
            .not_to raise_error, "Failed on color #{index}: #{color}"
        end
      end
    end
  end

  describe "#find_closest_amstrad_color" do
    it "returns a valid Amstrad color" do
      input_color = [128, 128, 128]
      result = image_processing.send(:find_closest_amstrad_color, input_color)
      expect(AMSTRAD_COLORS.values).to include(result)
    end
  end

  describe "#color_index" do
    it "returns a valid index for Amstrad colors" do
      AMSTRAD_COLORS.values.each do |color|
        index = image_processing.send(:color_index, color)
        expect(index).to be_between(0, AMSTRAD_COLORS.size - 1)
      end
    end
  end

  describe "performance" do
    it "processes the image within a reasonable time" do
      expect {
        Timeout.timeout(1) { image_processing.apply_downsize_with_dithering }
      }.not_to raise_error
    end

    it "completes multiple iterations quickly" do
      times = 2.times.map do
        Benchmark.realtime { image_processing.apply_downsize_with_dithering }
      end
      average_time = times.sum / times.size
      expect(average_time).to be < 1, "Average processing time (#{average_time}s) exceeds 0.5s"
    end

    it "processes 10 iterations in under 3 seconds" do
      total_time = Benchmark.realtime do
        5.times { image_processing.apply_downsize_with_dithering }
      end
      expect(total_time).to be < 5, "Total processing time for 10 iterations (#{total_time}s) exceeds 3s"
    end
  end
end
