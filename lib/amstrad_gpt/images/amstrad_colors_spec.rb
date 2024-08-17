# frozen_string_literal: true

require "amstrad_gpt/images/amstrad_colors"

RSpec.describe AmstradGpt::Images::AMSTRAD_COLORS do
  describe ".find_closest_amstrad_color" do
    it "returns a valid Amstrad color" do
      input_color = [128, 128, 128]
      result = AmstradGpt::Images.find_closest_amstrad_color(input_color)
      expect(described_class.values).to include(result)
    end
  end

  describe ".color_index" do
    it "returns a valid index for Amstrad colors" do
      described_class.values.each do |color|
        index = AmstradGpt::Images.color_index(color)
        expect(index).to be_between(0, described_class.size - 1)
      end
    end
  end
end
