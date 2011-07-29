# encoding: utf-8

module Scrabble
  class Hand
    class << self
      def create(tile_array)
        tile_array.each_with_object(Hand.new) { |t, h| h.add_tile(t) }
      end
    end

    def initialize
      @tiles = []
    end

    attr_reader :tiles

    def add_tile(tile)
      @tiles << Scrabble::Tile(tile)
    end

    def use(tile)
      where = @tiles.index(Scrabble::Tile(tile))
      @tiles.slice!(where, 1) if where
    end

    def include?(tile)
      @tiles.include?(Scrabble::Tile(tile))
    end

    def find(tile)
      @tiles.find { |t| t == Scrabble::Tile(tile) }
    end

    def to_s
      @tiles.to_s
    end

    def dup
      Marshal.load(Marshal.dump(self))
    end
  end
end

