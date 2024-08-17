#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "rspec"
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require "debug"
require "amstrad_gpt"
require "amstrad_gpt/images/response_handler"
require "amstrad_gpt/images/processing"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_image.rb [options]"

  opts.on("--path PATH", "The path of the saved image") do |path|
    options[:path] = path
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

if options[:path].nil?
  puts "Error: Path is required. Use -p or --path"
  exit 1
end

handler = AmstradGpt::Images::Processing.new(filename: options[:path])
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
  File.open("rle_#{options[:path]}", "wb") do |file|
    file.write(image_data)
  end

  puts "RLE encoded image saved to: rle_#{options[:path]}"
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
