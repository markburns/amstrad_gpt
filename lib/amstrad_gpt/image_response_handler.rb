require 'amstrad_gpt/image_processing'
require 'json'
require 'base64'
require 'open-uri'
require 'crack'
require 'amstrad_gpt/open_ai_connection'
require 'amstrad_gpt/debug'

module AmstradGpt
  class ImageResponseHandler
    include Debug

    def initialize(reply:, amstrad:, api_key:)
      @reply = reply
      @amstrad = amstrad
      @api_key = api_key
    end

    def process_and_send
      dalle_prompt = extract_dalle_prompt(@reply)

      begin
        image_url = generate_image(dalle_prompt)
        processed_image = process_image(image_url)
        encoded_image = encode_image_for_amstrad(processed_image)
        amstrad.send_to_amstrad("IMG:#{encoded_image}")
      rescue StandardError => e
        error_message = "Error generating image: #{e.message}"
        amstrad.send_to_amstrad("TXT:#{error_message}")
      end
    end

    private

    def extract_dalle_prompt(reply)
      parsed = Crack::JSON.parse(reply)
      parsed['dalle']
    end

    def generate_image(prompt)
      OpenAiConnection.image(
        api_key:,
        prompt:,
        size: '512x512',
      )
    end

    def process_image(image_url)
      # Download the image
      image_data = URI.open(image_url).read

      # Save the image temporarily
      temp_file = Tempfile.new(['image', '.png'])
      temp_file.binmode
      temp_file.write(image_data)
      temp_file.close

      # Process the image
      processor = ImageProcessing.new(temp_file.path)
      processed_image = processor.apply_downsize_with_dithering

      temp_file.unlink

      processed_image
    end

    def encode_image_for_amstrad(processed_image)
      # Convert the 2D array of RGB values to a string of Amstrad color indices
      colors = processed_image.map do |rgb|
        ImageProcessing.color_index(rgb)
      end

      # Perform run-length encoding
      rle_encoded = run_length_encode(colors)

      # Convert to Base64 for efficient transmission
      Base64.strict_encode64(rle_encoded.pack('C*'))
    end

    def run_length_encode(data)
      encoded = []
      count = 1
      last = data[0]

      data[1..-1].each do |current|
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

    attr_reader :reply, :amstrad, :api_key
  end
end
