# encoding: utf-8

module Robots
  class Factory
    IncorrectDirection = Class.new(StandardError)

    ALLOWED_DIRECTIONS = [:west, :east]

    class << self
      def create(floor_plan)
        factory       = Robots::Factory.new
        factory.floor = case
        when floor_plan.is_a?(String)
          floor.split("\n")
        when floor_plan.is_a?(Array)
          floor_plan
        when floor_plan.is_a?(::Robots::Factory)
          floor_plan.floor
        else
          raise TypeError, "Incorrect floor type"
        end

        factory
      end
    end

    def initialize(args={})
      @floor = []
      @floor = self.create(args[:floor]).floor if args[:floor]
    end

    attr_accessor :floor

    def north_wall
      @floor[0].each_char.to_a
    end

    def conveyor_belt
      @floor[1].each_char.to_a
    end

    def south_wall
      @floor[2].each_char.to_a
    end

    def robot_position
      conveyor_belt.index "X"
    end

    def compute_damage(direction)
      [north_wall, south_wall].map.with_index do |wall, wall_index|
        wall_part_for_direction(wall, direction).map.with_index do |c, pos|
          if c == "|"
            if wall_index.even? && pos.even?
              1
            elsif wall_index.odd? && pos.odd?
              1
            else
              0
            end
          else
            0
          end
        end.reduce(:+)
      end.reduce(:+)
    end

    def best_route
      ALLOWED_DIRECTIONS.sort_by { |dir| compute_damage(dir) }.first
    end

    private

    def wall_part_for_direction(wall, dir)
      raise IncorrectDirection unless ALLOWED_DIRECTIONS.include?(dir)

      result = case dir
      when :west
        wall.slice(0, robot_position+1).reverse
      when :east
        wall.slice(robot_position, wall.length)
      end
    end
  end

  class Processor
    def initialize(args={})
      @maps = []
      parse_factory_maps(args[:from_file]) if args[:from_file]
    end

    def add_map(m)
      @maps << m
    end

    def clear
      @maps = []
    end

    def get_best_routes
      @maps.map { |m| Factory.create(m).best_route }
    end

    def to_s
      get_best_routes.map { |r| "GO #{r.to_s.upcase}" }.join("\n")
    end

    private

    def parse_factory_maps(input_file)
      raise ArgumentError, "#{input_file} does not exist" unless File.exists?(input_file)
      @maps = File.read(input_file).split("\n\n").map! { |line| line.split("\n") }
    end
  end
end

input_file = ARGV[0] || 'sample-input.txt'
puts Robots::Processor.new(:from_file => input_file).to_s

