# encoding: utf-8

module Spelling
  module LCS
    def lcs_length(s1, s2)
      m = lcs_matrix(s1, s2)
      m[s1.size][s2.size]
    end

    private

    # from: http://en.wikipedia.org/wiki/Longest_common_subsequence_problem
    def lcs_matrix(s1, s2)
      m, n = s1.size, s2.size

      # (m+1)x(n+1) matrix
      c = Array.new(m+1) { Array.new(n+1, 0) }

      (1...m+1).each do |i|
        (1...n+1).each do |j|
          if s1[i-1] == s2[j-1]
            c[i][j] = c[i-1][j-1] + 1
          else
            c[i][j] = [c[i][j-1], c[i-1][j]].max
          end
        end
      end

      c
    end
  end

  class Suggestions
    include LCS

    def initialize(args={})
      parse_input(args[:from_file]) if args[:from_file]
    end

    def suggest(search, dict=[])
      return search if dict.empty?
      dict.sort_by { |s| lcs_length(search, s) }.last
    end

    private

    def parse_input(input_file)
      File.read(input_file).split("\n").map.with_index do |line, index|
        if index < 2 || line.strip.empty?
          nil
        else
          line.strip.chomp
        end
      end.compact.each_slice(3).map do |data|
        puts suggest(data[0], [data[1], data[2]])
      end
    end
  end
end

Spelling::Suggestions.new(:from_file => (ARGV[0] || 'SAMPLE_INPUT.txt'))

