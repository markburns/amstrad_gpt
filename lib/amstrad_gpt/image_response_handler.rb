require 'amstrad_gpt/image_processing'
require 'json'
require 'base64'
require 'open-uri'

module AmstradGpt
  class ImageResponseHandler
    include Debug

    def initialize(reply:, amstrad:, connection:)
      @api_ke
      @reply = reply
      @amstrad = amstrad
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
      # the regex is a bit flexible here
      # as ChatGPT is not consistent in the format of the reply
      match = reply.match(/\{'?dalle'?: "(.*?)"?\}?/)
      match[1] if match
    end

    def generate_image(prompt)
      api_key = ENV['OPENAI_API_KEY']
      url = 'https://api.openai.com/v1/images/generations'

      body = {
        prompt:,
        n: 1,
        size: '512x512',
        response_format: 'url'
      }

      connection = Faraday.new(url:) do |faraday|
        faraday.headers['Content-Type'] = 'application/json'
        faraday.headers['Authorization'] = "Bearer #{api_key}"
        faraday.adapter Faraday.default_adapter
      end

      response = connection.post do |req|
        req.body = body.to_json
      end

      if response.success?
        JSON.parse(response.body)['data'][0]['url']
      else
        raise "Image generation failed: #{response.status} #{response.body}"
      end
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

    attr_reader :reply, :amstrad
  end
end
