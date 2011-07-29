# encoding: utf-8

module Scrabble
  module Word
    def to_tiles(with_hand)
      each_char.map { |l| with_hand.find(l) }
    end

    def compute_score(with_hand)
      to_tiles(with_hand).inject(0) { |sum, tile| sum + tile.score }
    end

    def valid_for?(with_hand)
      hand = with_hand.dup
      each_char.all? { |letter| !!hand.use(letter) }
    end
  end
end

