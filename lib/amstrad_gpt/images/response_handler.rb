# frozen_string_literal: true

require "amstrad_gpt/images/processing"
require "json"
require "base64"
require "open-uri"
require "amstrad_gpt/open_ai_connection"
require "amstrad_gpt/debug"
require_relative './amstrad_colors'
require "tempfile"

module AmstradGpt
  module Images
    class ResponseHandler
      include Debug

      def self.call(...)
        new(...).call
      end

      def initialize(reply:, api_key:, output_filename: nil)
        @reply = reply
        @api_key = api_key
        @output_filename = output_filename
      end

      def call
        dalle_prompt = embellish(@reply)

        begin
          debug "Generating image for prompt: #{dalle_prompt}"
          image_url = generate_image(dalle_prompt)
          debug "Processing image from URL: #{image_url}"
          processed_image = process_image(image_url)
          debug "Saving processed image"
          save_processed_image(processed_image)
          debug "Encoding image for Amstrad"
          rle_image = encode_image_for_amstrad(processed_image)

          "IMG:#{rle_image}"
        rescue StandardError => e
          debug("Error in Images::ResponseHandler#call: #{e.message}")
          debug("Backtrace:\n#{e.backtrace.join("\n")}")

          "TXT:Error processing image: #{e.message}. Please check the logs for more details."
        end
      end

      def embellish(main_theme)
        <<~PROMPT
          You are a famous artist who has been asked to create an original
          image based on the following criteria:

          Main Theme: #{main_theme}
          It should be colorful, realistic, minimalistic, and somewhat of a challenge to replicate.
          It should only contain the “Main Theme” and no other elements in the foreground, background or surrounding space.
          It should contain the “Main Theme” only once with no margins above, below or on either side.
          The “Main Theme” should consume the entire image space.
          It should not divide the “Main Theme” into separate parts of the image nor imply any variations of it.
          It should only contain photographic elements 
          The image should be suitable for digital printing without any instructional or guiding elements.
        PROMPT
      end

      def save_processed_image(processed_image)
        return if @output_filename.nil?

        png = ChunkyPNG::Image.new(
          Images::Processing::TARGET_WIDTH,
          Images::Processing::TARGET_HEIGHT,
          ChunkyPNG::Color::TRANSPARENT
        )
        processed_image.each_with_index do |row, y|
          row.each_with_index do |(r, g, b), x|
            png[x, y] = ChunkyPNG::Color.rgb(r, g, b)
          end
        end
        png.save(@output_filename, interlace: true)
        yield @output_filename if block_given?
      end

      private

      def generate_image(prompt)
        OpenAiConnection.image(
          api_key:,
          prompt:,
          size: "1792x1024"
        )
      end

      def process_image(image_url)
        # Download the image
        response = Faraday.get(image_url)
        image_data = response.body if response.success?

        # Save the image temporarily
        temp_file = Tempfile.new(["image", ".png"])
        temp_file.binmode
        temp_file.write(image_data)
        temp_file.close

        # Process the image
        processor = Processing.new(input_filename: temp_file.path, output_filename: @output_filename)
        processed_image = processor.apply_downsize_with_dithering

        temp_file.unlink

        processed_image
      end

      def encode_image_for_amstrad(processed_image)
        begin
          # Convert the 2D array of RGB values to a string of Amstrad color indices
          colors = processed_image.flatten(1).map do |rgb|
            Images.lookup(rgb) || 0
          end

          # Perform run-length encoding
          rle_encoded = run_length_encode(colors)

          # Convert to Base64 for efficient transmission
          Base64.strict_encode64(rle_encoded.pack("C*"))
        rescue StandardError => e
          debug("Error in encode_image_for_amstrad: #{e.message}")
          debug("processed_image: #{processed_image.inspect}")
          debug("colors: #{colors.inspect}") if defined?(colors)
          debug("rle_encoded: #{rle_encoded.inspect}") if defined?(rle_encoded)
          raise
        end
      end

      def run_length_encode(data)
        encoded = []
        count = 1
        last = data[0]

        data[1..].each do |current|
          if current == last && count < 255
            count += 1
          else
            encoded << count << last
            count = 1
            last = current
          end
        end

        encoded << count << last
        encoded
      end

      attr_reader :reply, :api_key
    end
  end
end
