# encoding: utf-8

module Scrabble
  class Tile
    class << self
      def create(tile_string)
        letter, score = tile_string[0], tile_string[1, tile_string.size]
        Tile.new(letter, score)
      end
    end

    include Comparable

    def initialize(letter, score=0)
      @letter = letter.strip
      @score  = score.to_i
    end

    attr_accessor :letter, :score

    def to_s
      "#{letter}(#{score})"
    end

    def <=>(other)
      @letter <=> other.letter
    end
  end

  # typecast wrapper
  def self.Tile(input)
    case
      when input.is_a?(String)
        Scrabble::Tile.create(input)
      when input.is_a?(Scrabble::Tile)
        input
      else
        raise ArgumentError, "Cannot typecast #{input.class} into Scrabble::Tile"
    end
  end
end

