module AmstradGpt
  module Images
    load 'large/amstrad_gpt/images/color_lookup_table.rb'

    AMSTRAD_COLORS = {
      black: [0, 0, 0],
      blue: [0, 0, 128],
      bright_blue: [0, 0, 255],
      red: [128, 0, 0],
      magenta: [128, 0, 128],
      mauve: [128, 0, 255],
      bright_red: [255, 0, 0],
      purple: [255, 0, 128],
      bright_magenta: [255, 0, 255],
      green: [0, 128, 0],
      cyan: [0, 128, 128],
      sky_blue: [0, 128, 255],
      yellow: [128, 128, 0],
      white: [128, 128, 128],
      pastel_blue: [128, 128, 255],
      orange: [255, 128, 0],
      pink: [255, 128, 128],
      pastel_magenta: [255, 128, 255],
      bright_green: [0, 255, 0],
      sea_green: [0, 255, 128],
      bright_cyan: [0, 255, 255],
      lime: [128, 255, 0],
      pastel_green: [128, 255, 128],
      pastel_cyan: [128, 255, 255],
      bright_yellow: [255, 255, 0],
      pastel_yellow: [255, 255, 128],
      bright_white: [255, 255, 255]
    }.freeze

    class << self
      def lookup(rgb_24_bit)
        closest_color = COLOR_LOOKUP[rgb_24_bit]
        color_index(closest_color)
      end

      def find_closest_amstrad_color(input_color)
        AMSTRAD_COLORS.values.min_by do |amstrad_color|
          euclidean_distance(input_color, amstrad_color)
        end
      end

      def euclidean_distance(color1, color2)
        Math.sqrt(
          (color1[0] - color2[0])**2 +
          (color1[1] - color2[1])**2 +
          (color1[2] - color2[2])**2
        )
      end

      def color_index(color)
        AMSTRAD_COLORS.values.index(color) || 0
      end
    end
  end
end
