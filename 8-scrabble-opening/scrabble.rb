# encoding: utf-8

require 'json'
require 'pp'

module Scrabble
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

  class Tile
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

    def self.create(tile_string)
      letter, score = tile_string[0], tile_string[1, tile_string.size]
      Tile.new(letter, score)
    end
  end

  class Hand
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

    def self.create(tile_array)
      tile_array.each_with_object(Hand.new) { |t, h| h.add_tile(t) }
    end
  end

  class Dictionary
    def initialize
      @words = []
    end

    attr_reader :words

    def add_word(word)
      @words << word unless @words.include?(word)
    end

    def discard_many(discards)
      @words.reject! { |word| discards.include?(word) }
    end

    def to_s
      @words.to_s
    end

    def self.create(word_array)
      word_array.each_with_object(Dictionary.new) { |w, d| d.add_word(w) }
    end
  end

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
      unless @tile
        @multiplier.to_s
      else
        @tile.letter
      end
    end
  end

  class Board
    IllegalPositionError  = Class.new(StandardError)

    def initialize(rows, cols)
      @num_rows = rows
      @num_cols = cols
      @squares  = Array.new(@num_rows*@num_cols, Square.new)
    end

    attr_reader :num_rows, :num_cols
    attr_accessor :squares

    def [](x, y)
      raise IllegalPositionError, "Illegal position [#{x}, #{y}]" unless valid_position?(x, y)
      @squares[translate(x, y)]
    end

    def []=(x, y, square)
      case
        when square.is_a?(Square)
          @squares[translate(x, y)] = square
        when square.is_a?(Tile)
          @squares[translate(x, y)].tile = square
        else
          raise TypeError, "Don't know what to do with that input"
      end
    end

    def rows
      squares.each_slice(@num_cols).to_a
    end

    def columns
      rows.transpose
    end

    def score
      @squares.map { |sq| sq.score }.reduce(:+)
    end

    def to_a
      rows.map { |row| row.map(&:to_s).join(' ') }
    end

    def to_s
      self.to_a.join("\n")
    end

    def dup
      Marshal.load(Marshal.dump(self))
    end

    def self.restore(board)
      case
        when board.is_a?(Scrabble::Board)
          board.dup
        when board.is_a?(Array)
          restore_from_array(board)
        when board.is_a?(String)
          restore_from_array(board.split("\n"))
        else
          raise TypeError, "Cannot restore #{board} into Scrabble::Board"
      end
    end

    private

    def translate(x,y)
      x + num_cols*y
    end

    def valid_position?(x, y)
      (0...num_rows).include?(x) && (0...num_cols).include?(y)
    end

    def self.restore_from_array(array)
      squares = array.map { |row| row.split(' ') }
      board   = Board.new(squares.size, squares.first.size)

      squares.each_with_index do |row, j|
        row.each_with_index do |value, i|
          board[i, j] = Square.new(nil, value.to_i)
        end
      end

      board
    end
  end

  class Opening
    def initialize(args={})
      @board      = args.fetch(:board)
      @hand       = args.fetch(:hand)
      @dictionary = args.fetch(:dictionary)

      discard_bad_words
    end

    attr_reader :board, :hand, :dictionary

    def find_best
      max_score_words = find_best_guesses
      max_boards = max_score_words.map { |word| find_best_placement(to_tiles(word)) }

      max_boards.sort_by { |board| -board.score }.first
    end

    class << self
      def parse(input_file)
        data = JSON.parse(File.read(input_file))

        Opening.new(
          :board      => Board.restore(data['board']),
          :hand       => Hand.create(data['tiles']),
          :dictionary => Dictionary.create(data['dictionary'])
        )
      end
    end

    private

    # chunky, clunky... sigh

    def find_best_guesses
      max_score = @dictionary.words.map { |word| compute_score(word) }.max
      @dictionary.words.reject { |word| compute_score(word) != max_score }
    end

    def compute_score(word)
      to_tiles(word).map(&:score).reduce(:+)
    end

    def to_tiles(word)
      word.each_char.map { |letter| @hand.find(letter) }
    end

    def discard_bad_words
      unformable = @dictionary.words.each_with_object([]) do |word, discards|
        if word.size > @board.num_rows && word.size > @board.num_cols
          discards << word
        else
          hand = @hand.dup

          word.each_char do |letter|
            if hand.include?(letter)
              hand.use(letter)
            else
              discards << word
              break # => BIG WTF!
            end
          end
        end
      end

      @dictionary.discard_many(unformable)
    end

    def find_placements_by_row(tiles)
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

    def find_placements_by_column(tiles)
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

    def find_best_placement(tiles)
      boards = find_placements_by_row(tiles) + find_placements_by_column(tiles)
      boards.sort_by { |board| -board.score }.first
    end
  end
end

opening = Scrabble::Opening.parse(ARGV[0] || 'EXAMPLE_INPUT.json').find_best
puts opening

