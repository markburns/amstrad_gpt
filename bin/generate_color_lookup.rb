require 'json'
require 'debug'
require_relative './amstrad_colors'
color_lookup = {}

puts 'calculating color lookup table...'
(0..31).each do |r|
  (0..31).each do |g|
    (0..31).each do |b|
      red = r * 8
      green = g * 8
      blue = b * 8
      puts "r: #{red}, g: #{green}, b: #{blue}"
      color_lookup[[r, g, b]] = AmstradColors.find_closest_amstrad_color([red, green, blue])
    end
  end
end

puts 'calculated color lookup table'

File.open('lib/large/amstrad_gpt/images/color_lookup_table.rb', 'w') do |f|
  f.write("module AmstradGpt\n  module Images\n\nCOLOR_LOOKUP = #{color_lookup}")
end


