require 'amstrad_gpt/image_processing'
require 'json'
require 'base64'
require 'open-uri'

module AmstradGpt
  class ImageResponseHandler
    include Debug

    def initialize(reply:, amstrad:)
      @reply = reply
      @amstrad = amstrad
    end

    def process_and_send
      dalle_prompt = extract_dalle_prompt(@reply)
      image_url = generate_image(dalle_prompt)
      processed_image = process_image(image_url)
      encoded_image = encode_image_for_amstrad(processed_image)
      @amstrad.send_to_amstrad("IMG:#{encoded_image}")
    end

    private

    def extract_dalle_prompt(reply)
      match = reply.match(/\{dalle: "(.*?)"\}/)
      match[1] if match
    end

    def generate_image(prompt)
      # This is a placeholder. You'll need to implement the actual DALL-E API call here.
      # For now, we'll just return a placeholder image URL.
      "https://via.placeholder.com/320x200"
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
      color_indices = processed_image.flatten(1).map do |rgb|
        ImageProcessing::AMSTRAD_COLORS.values.index(rgb)
      end

      # Perform run-length encoding
      rle_encoded = run_length_encode(color_indices)

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
  end
end
