# encoding: utf-8

module Steganography
  class Bitmap
    module Offsets
      DIMENSIONS        = 0x12
      PIXEL_DATA        = 0x0A
      PIXEL_DATA_SIZE   = 0x22
    end

    def initialize(buffer)
      @buffer = buffer.force_encoding('BINARY')
    end

    def width
      return 0 if @buffer.empty?
      @width ||= @buffer[Offsets::DIMENSIONS,4].unpack('l')[0]
    end

    def height
      return 0 if @buffer.empty?
      @height ||= @buffer[Offsets::DIMENSIONS+4,4].unpack('l')[0]
    end

    def bpp
      return 0 if @buffer.empty?
      @bpp ||= @buffer[Offsets::DIMENSIONS+8,2].unpack('S')[0]
    end

    def pixels
      return [] if @buffer.empty?
      @pixel_data ||= @buffer[pixel_data_start, pixel_data_size].unpack('C*')
    end

    def to_s
      "Bitmap (#{width}x#{height}@#{bpp})"
    end

    def save_as(filename)
      bytes = "".force_encoding('BINARY')

      bytes << @buffer[0, pixel_data_start]
      bytes << pixels.pack('C*')
      bytes << @buffer[pixel_data_start+pixel_data_size, @buffer.size]

      File.open(filename, 'wb') { |file| file.write(bytes) }
    end

    class << self
      def load(filename)
        Bitmap.new(File.read(filename))
      end
    end

    private

    def pixel_data_start
      @pixel_data_start ||= @buffer[Offsets::PIXEL_DATA,4].unpack('L')[0]
    end

    def pixel_data_size
      @pixel_data_size ||= @buffer[Offsets::PIXEL_DATA_SIZE,4].unpack('L')[0]
    end
  end

  class Encoder
    def initialize(text, bitmap)
      @text   = text
      @bitmap = bitmap
    end

    attr_reader :text, :bitmap

    def encode
      binary_text = @text.unpack('B*').first

      if binary_text.size <= @bitmap.pixels.size
        binary_enum = binary_text.each_char

        @bitmap.pixels.each_with_index do |pixel, index|
          bit = binary_enum.next rescue nil

          bin     = pixel.chr.unpack('b*').first
          bin[0]  = bit || '0'

          @bitmap.pixels[index] = [bin].pack('b*').unpack('C*').first
        end
      else
        raise 'WTF!? Text would not fit inside this image.'
      end
    end

    def decode
    end

    def save_as(output_file)
      @bitmap.save_as(output_file)
    end

    class << self
      def encode(text_file, input_image, output_image='output.bmp')
        text    = File.read(text_file)
        bitmap  = Bitmap.load(input_image)

        encoder = Encoder.new(text, bitmap)
        encoder.encode
        encoder.save_as(output_image)
      end
    end
  end

  class Decoder
    def initialize(bitmap)
      @bitmap = bitmap
    end

    attr_reader :bitmap

    def decode
      bits = get_pixels_lsb(@bitmap.pixels)
      text = bits.each_slice(8).map { |byte| [byte.join('')].pack('B*') }
      text.reject { |char| char == "\x00" }.join('')
    end

    class << self
      def decode(input_image)
        bitmap  = Bitmap.load(input_image)

        decoder = Decoder.new(bitmap)
        puts decoder.decode
      end
    end

    private

    def get_pixels_lsb(pixels)
      pixels.each_with_object([]) do |pix, bits|
        bits << pix.chr.unpack('b*').first[0]
      end
    end
  end
end

input_text  = ARGV[0] || 'sample_input.txt'
input_image = ARGV[1] || 'input.bmp'
Steganography::Encoder.encode(input_text, input_image)

