# encoding: utf-8

module Scrabble
  class BestOpening
    class << self
      def parse(input_file)
        data = JSON.parse(File.read(input_file))

        BestOpening.new(
          :board      => Board.restore(data['board']),
          :hand       => Hand.create(data['tiles']),
          :dictionary => data['dictionary']
        )
      end
    end

    def initialize(args={})
      @board      = args.fetch(:board)
      @hand       = args.fetch(:hand)
      @dictionary = args.fetch(:dictionary, [])
    end

    attr_reader :board, :hand, :dictionary

    def find
      possible_words  = find_best_words(valid_words)
      openings        = possible_words.map do |word|
        find_best_opening( word.to_tiles(@hand) )
      end

      openings.max_by { |opening| opening.score }
    end

    private

    def valid_words
      @dictionary.select do |word|
        word.valid_for?(@hand) && word.size <= @board.num_rows && word.size <= @board.num_cols
      end
    end

    def find_best_words(words)
      max_score = words.map { |word| word.compute_score(@hand) }.max
      words.select { |word| word.compute_score(@hand) == max_score }
    end

    def find_best_opening(tiles)
      boards = find_openings_by_row(tiles) + find_openings_by_column(tiles)
      boards.max_by { |board| board.score }
    end

    def find_openings_by_row(tiles)
      boards        = []
      row_range     = 0...@board.rows.size
      column_range  = (0..(@board.columns.size-tiles.size))

      row_range.each do |y|
        column_range.each do |x|
          tmp_board = @board.dup
          tiles.each_with_index { |tile, idx| tmp_board[x+idx, y] = tile }
          boards << tmp_board
        end
      end

      boards
    end

    def find_openings_by_column(tiles)
      boards        = []
      column_range  = 0...@board.columns.size
      row_range     = (0..(@board.rows.size-tiles.size))

      column_range.each do |x|
        row_range.each do |y|
          tmp_board = @board.dup
          tiles.each_with_index { |tile, idx| tmp_board[x, y+idx] = tile }
          boards << tmp_board
        end
      end

      boards
    end
  end
end

