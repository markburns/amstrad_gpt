# frozen_string_literal: true

require "chunky_png"

module AmstradGpt
  module Images
    class Processing
      TARGET_WIDTH = 320
      TARGET_HEIGHT = 200

      load './lib/large/color_lookup_table.rb'

      def initialize(input_filename:, output_filename:)
        @input_filename = input_filename
        @output_filename = output_filename
      end

      def x_scale = width / TARGET_WIDTH
      def y_scale = height / TARGET_HEIGHT

      def image
        @image ||= ChunkyPNG::Image.from_file(@input_filename)
      end

      def width = image.width.to_f
      def height = image.height.to_f

      def call
        # Process the image to downsize and directly apply dithering
        dithered_image = apply_downsize_with_dithering
        save_image(dithered_image)
      end

      def downsized_image_array
        @downsized_image_array ||= TARGET_WIDTH.times.map do |x|
          TARGET_HEIGHT.times.map do |y|
            avg_color = average_block_color(
              start_x: x * x_scale,
              start_y: y * y_scale
            )

            COLOR_LOOKUP[avg_color]
          end
        end
      end

      def apply_downsize_with_dithering
        target_image = Array.new(TARGET_HEIGHT) { Array.new(TARGET_WIDTH, [0, 0, 0]) }
        error_map = Array.new(TARGET_HEIGHT + 2) { Array.new(TARGET_WIDTH + 2, [0, 0, 0]) }

        x_ratio = (width * 256 / TARGET_WIDTH).to_i
        y_ratio = (height * 256 / TARGET_HEIGHT).to_i

        TARGET_HEIGHT.times do |target_y|
          TARGET_WIDTH.times do |target_x|
            x = (target_x * x_ratio) >> 8
            y = (target_y * y_ratio) >> 8

            color = image[x, y]
            red = (color >> 16) & 0xFF
            green = (color >> 8) & 0xFF
            blue = color & 0xFF

            r = red   + (error_map[target_y][target_x][0]).clamp(0, 255).to_i
            g = green + (error_map[target_y][target_x][1]).clamp(0, 255).to_i
            b = blue  + (error_map[target_y][target_x][2]).clamp(0, 255).to_i

            # Increase brightness and contrast
            r = (((r - 128) * 1.5) + 128).clamp(0, 255).to_i
            g = (((g - 128) * 1.5) + 128).clamp(0, 255).to_i
            b = (((b - 128) * 1.5) + 128).clamp(0, 255).to_i

            # # # Adjust color balance to emphasize reds and yellows
            r = (r * 1.3).clamp(0, 255).to_i
            g = (g * 1.1).clamp(0, 255).to_i
            b = (b * 0.7).clamp(0, 255).to_i

            r = r >> 3
            g = g >> 3
            b = b >> 3

            chosen_color = COLOR_LOOKUP[[r, g, b ]]
            target_image[target_y][target_x] = chosen_color

            error = [
              r - chosen_color[0],
              g - chosen_color[1],
              b - chosen_color[2]
            ]
            distribute_error(error_map, target_x, target_y, error)
          rescue StandardError => e
            puts e.backtrace
            puts e.message
            exit
          end
        end

        target_image
      end

      def distribute_error(error_map, x, y, error)
        red_error, green_error, blue_error = error
        [
          [x + 1, y, 5.0 / 16],
          [x - 1, y + 1, 3.0 / 16],
          [x, y + 1, 3.0 / 16],
          [x + 1, y + 1, 5.0 / 16]
        ].each do |nx, ny, factor|
          next if nx < 0 || ny < 0 || nx >= TARGET_WIDTH || ny >= TARGET_HEIGHT

          error_map[ny][nx][0] += (red_error * factor).round
          error_map[ny][nx][1] += (green_error * factor).round
          error_map[ny][nx][2] += (blue_error * factor).round
        end
      end

      def save_image(color_array)
        png = ChunkyPNG::Image.new(TARGET_WIDTH, TARGET_HEIGHT, ChunkyPNG::Color::TRANSPARENT)

        color_array.each_with_index do |row, x|
          row.each_with_index do |(r, g, b), y|
            png[y, x] = ChunkyPNG::Color.rgb(r, g, b)
          end
        end

        png.save(@output_filename, interlace: true)
      end

      def apply_atkinson_dithering(color_array)
        height = color_array.length
        width = color_array.first.length

        new_color_array = Marshal.load(Marshal.dump(color_array)) # Deep copy of the color array

        height.times do |y|
          width.times do |x|
            old_pixel = new_color_array[y][x]
            new_pixel = COLOR_LOOKUP[old_pixel]
            color_array[y][x] = new_pixel

            error = [
              old_pixel[0] - new_pixel[0],
              old_pixel[1] - new_pixel[1],
              old_pixel[2] - new_pixel[2]
            ]

            # Spread the error to neighboring pixels
            [
              [1, 0], [2, 0],
              [1, 1], [2, 1],
              [1, 2]
            ].each_with_index do |(dx, dy), _index|
              nx = x + dx
              ny = y + dy
              next if ny >= height || nx >= width

              fraction = error.map { |e| (e * (1.0 / 8)).round }

              with_error = new_color_array[ny][nx].zip(fraction)

              new_color_array[ny][nx] = with_error.map do |original, err|
                (original + err).clamp(0, 255)
              end
            end
          end
        end

        new_color_array
      end

      def average_block_color(start_x:, start_y:)
        total_r = total_g = total_b = 0
        count = 0

        # Calculate the end coordinates for the block
        end_x = [start_x + x_scale, width].min
        end_y = [start_y + y_scale, height].min

        (start_x.to_i...end_x.to_i).each do |px|
          (start_y.to_i...end_y.to_i).each do |py|
            pixel = image[px, py]

            r = (pixel >> 24) & 255
            g = (pixel >> 16) & 255
            b = (pixel >> 8) & 255

            total_r += r
            total_g += g
            total_b += b

            count += 1
          end
        end

        if count.positive?
          avg_r = (total_r / count).round
          avg_g = (total_g / count).round
          avg_b = (total_b / count).round
        else
          avg_r = avg_g = avg_b = 0 # Fallback in case no pixels were counted
        end

        [avg_r, avg_g, avg_b]
      end
    end
  end
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
