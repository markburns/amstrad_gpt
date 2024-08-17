#!/usr/bin/env ruby
# frozen_string_literal: true

require 'active_support/all'
require "optparse"
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require "debug"
require "amstrad_gpt"
require "amstrad_gpt/images/response_handler"
require "amstrad_gpt/images/processing"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_image.rb [options]"

  opts.on("-p", "--prompt PROMPT", "The prompt for image generation") do |prompt|
    options[:prompt] = prompt
  end

  opts.on("--path PATH", "The path to save the generated image") do |path|
    options[:path] = path
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:prompt].nil?
  puts "Error: Prompt is required. Use -p or --prompt to specify a prompt."
  exit 1
end

options[:path] ||= "images/#{options[:prompt].gsub(/[^a-z0-9]/, '-').dasherize}.png"

# Simulate the ChatGPT response
chatgpt_response = { "dalle" => options[:prompt] }.to_json

# Use ImageResponseHandler to generate the image
api_key = ENV["OPENAI_API_KEY"]
if api_key.nil?
  puts "Error: OPENAI_API_KEY environment variable is not set."
  exit 1
end

handler = AmstradGpt::Images::ResponseHandler.new(
  api_key:,
  reply: chatgpt_response, 
  output_filename: options[:path]
)

processed_image_path = nil

handler.define_singleton_method(:save_processed_image) do |processed_image|
  super(processed_image) do |path|
    processed_image_path = path
  end
end

result = handler.call

if result.start_with?("IMG:")
  # Extract the Base64 encoded image data
  image_data = Base64.strict_decode64(result[4..-1])

  # Save the RLE encoded image
  rle_image = options[:path].gsub(/\.png$/, ".rle").gsub("images/", "images/rle_")
  File.open(rle_image, "wb") do |file|
    file.write(image_data)
  end

  puts "RLE encoded image saved to: #{options[:path]}"
  puts "Processed image saved to:   #{processed_image_path}"

  # Display inline in terminal (this works in some terminals that support sixel graphics)
  # Note: This might not work in all environments
  begin
    system("img2sixel #{processed_image_path}")
  rescue StandardError => e
    puts "Could not display image inline: #{e.message}"
  end
else
  puts "Error generating image: #{result}"
end
