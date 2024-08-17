require 'json'
require 'debug'
require_relative './amstrad_colors'
color_lookup = {}



def find_closest_amstrad_color(b)
  AMSTRAD_COLORS.values.min_by do |a|
    ((b[0] - a[0])**2) + ((b[1] - a[1])**2) + ((b[2] - a[2])**2)
  end
end

puts 'calculating color lookup table...'
(0..31).each do |r|
  (0..31).each do |g|
    (0..31).each do |b|
      red = r * 8
      green = g * 8
      blue = b * 8
      puts "r: #{red}, g: #{green}, b: #{blue}"
      color_lookup[[r, g, b]] = find_closest_amstrad_color([red, green, blue])
    end
  end
end

puts 'calculated color lookup table'

File.open('lib/large/color_lookup_table.rb', 'w') do |f|
  f.write("module AmstradGpt\n  module Images\n\nCOLOR_LOOKUP = #{color_lookup}\n  end\nend")
end


