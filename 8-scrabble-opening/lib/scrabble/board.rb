# encoding: utf-8

module Scrabble
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
end

