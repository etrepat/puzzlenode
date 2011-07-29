# encoding: utf-8

module Scrabble
  class Square
    def initialize(tile=nil, multiplier=1)
      @tile       = tile
      @multiplier = multiplier
    end

    attr_accessor :tile
    attr_reader :multiplier

    def score
      return multiplier unless tile
      tile.score * multiplier
    end

    def to_s
      @tile ? @tile.letter : @multiplier.to_s
    end
  end
end

