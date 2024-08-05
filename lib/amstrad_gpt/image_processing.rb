require 'chunky_png'

module AmstradGpt
  class ImageProcessing
    TARGET_WIDTH = 320
    TARGET_HEIGHT = 200

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
      bright_white: [255, 255, 255],
    }

    def initialize(filename)
      @filename = filename
    end

    def x_scale = width / TARGET_WIDTH
    def y_scale = height / TARGET_HEIGHT

    def image
      @image ||= ChunkyPNG::Image.from_file(@filename)
    end

    def width = image.width.to_f
    def height = image.height.to_f

    def call
      # Process the image to downsize and directly apply dithering
      dithered_image = apply_downsize_with_dithering
      save_image(dithered_image, "dithered_output.png")
    end

    def downsized_image_array
      @downsized_image_array ||= TARGET_WIDTH.times.map do |x|
        TARGET_HEIGHT.times.map do |y|
          avg_color = average_block_color(start_x: x * x_scale,
                                          start_y: y * y_scale)
          find_closest_amstrad_color(avg_color)
        end
      end
    end

    def apply_downsize_with_dithering
      target_image = Array.new(TARGET_HEIGHT) { Array.new(TARGET_WIDTH, [0, 0, 0]) }
      error_map = Array.new(height) { Array.new(width, [0, 0, 0]) }

      TARGET_WIDTH.times do |target_x|
        TARGET_HEIGHT.times do |target_y|
          total_r = total_g = total_b = count = 0

          # Calculate the range of original pixels contributing to this target pixel
          start_x = (target_x * x_scale).floor
          end_x = [(start_x + x_scale).ceil, width].min
          start_y = (target_y * y_scale).floor
          end_y = [(start_y + y_scale).ceil, height].min

          (start_x...end_x).each do |x|
            (start_y...end_y).each do |y|
              # Fetch the pixel from the original image and apply any existing error

              color = image[x, y]

              r = (color >> 16) & 0xFF + error_map[y][x][0]
              g = (color >> 8) & 0xFF + error_map[y][x][1]
              b = (color & 0xFF) + error_map[y][x][2]

              r = r.clamp(0, 255)
              g = g.clamp(0, 255)
              b = b.clamp(0, 255)

              # Calculate contribution weight (overlap area or simple count)
              weight = 1 # Simplified for illustration; can be adjusted for actual overlap area
              total_r += r * weight
              total_g += g * weight
              total_b += b * weight
              count += weight
            end
          end

          # Compute the average color for this target pixel
          avg_color = [total_r / count, total_g / count, total_b / count].map(&:to_i)
          chosen_color = find_closest_amstrad_color(avg_color)
          target_image[target_y][target_x] = chosen_color

          # Calculate the error and distribute it
          error = [avg_color[0] - chosen_color[0], avg_color[1] - chosen_color[1], avg_color[2] - chosen_color[2]]
          [[1, 0], [0, 1]].each do |dx, dy|
            nx, ny = target_x + dx, target_y + dy
            next if nx >= TARGET_WIDTH || ny >= TARGET_HEIGHT
            error_map[ny][nx] = error.map { |e| e * (1.0 / 2) } # Simplified error distribution
          end
        end
      end

      target_image
    end

    def save_image(color_array, filename)
      png = ChunkyPNG::Image.new(TARGET_WIDTH, TARGET_HEIGHT, ChunkyPNG::Color::TRANSPARENT)

      color_array.each_with_index do |row, x|
        row.each_with_index do |(r, g, b), y|
          png[y, x] = ChunkyPNG::Color.rgb(r, g, b)
        end
      end

      png.save(filename, interlace: true)
    end

    def apply_dithering(color_array)
      height = color_array.length
      width = color_array.first.length
      error_map = Array.new(height) { Array.new(width, [0, 0, 0]) }

      height.times do |y|
        width.times do |x|
          original = color_array[y][x].zip(error_map[y][x]).map { |c, e| (c + e).clamp(0, 255) }
          closest_color = find_closest_amstrad_color(original)
          color_array[y][x] = closest_color

          error = [original[0] - closest_color[0], original[1] - closest_color[1], original[2] - closest_color[2]]
          puts "Error at (#{x}, #{y}): #{error}"

          # Error diffusion to the right and down
          [[1, 0, 7.0 / 16], [-1, 1, 3.0 / 16], [0, 1, 5.0 / 16], [1, 1, 1.0 / 16]].each do |dx, dy, ratio|
            nx, ny = x + dx, y + dy
            next if nx < 0 || ny < 0 || nx >= width || ny >= height

            error_map[ny][nx] = error_map[ny][nx].zip(error.map { |e| e * ratio }).map(&:sum)
          end
        end
      end

      color_array
    end

    def apply_atkinson_dithering(color_array)
      height = color_array.length
      width = color_array.first.length

      new_color_array = Marshal.load(Marshal.dump(color_array)) # Deep copy of the color array

      height.times do |y|
        width.times do |x|
          old_pixel = new_color_array[y][x]
          new_pixel = find_closest_amstrad_color(old_pixel)
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
          ].each_with_index do |(dx, dy), index|
            nx, ny = x + dx, y + dy
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

      if count > 0
        avg_r = (total_r / count).round
        avg_g = (total_g / count).round
        avg_b = (total_b / count).round
      else
        avg_r = avg_g = avg_b = 0 # Fallback in case no pixels were counted
      end

      [avg_r, avg_g, avg_b]
    end

    def find_closest_amstrad_color(color)
      min_distance = Float::INFINITY
      closest_color = nil

      AMSTRAD_COLORS.each_value do |amstrad_color|
        distance = euclidean_color_distance(amstrad_color, color)

        if distance < min_distance
          min_distance = distance
          closest_color = amstrad_color
        end
      end

      closest_color
    end

    def euclidean_color_distance(a, b)
      Math.sqrt(
        (b[0] - a[0])**2 +
        (b[1] - a[1])**2 +
        (b[2] - a[2])**2
      )
    end
  end
end
