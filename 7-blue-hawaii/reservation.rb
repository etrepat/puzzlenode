# encoding: utf-8

require 'json'

module Reservation
  module TimeUtils
    def set_time(t, hour = 0, minute = 0, second = 0, usec = 0.000000)
      Time.utc(t.year, t.month, t.day, hour, minute, second, usec)
    end

    def clear_time(t)
      set_time(t)
    end
  end

  class TimeSpan
    include TimeUtils

    def initialize(args={})
      @start_date   = args.fetch(:start_date, Time.now.utc)
      @end_date     = args.fetch(:end_date, Time.now.utc + 86400)
    end

    attr_accessor :start_date, :end_date
  end

  class Period < TimeSpan
    def range
      output = []

      to      = clear_time(end_date)
      current = set_time(start_date, 15)
      while current < to
        output << current
        current = clear_time(current + 86400)
      end

      output
    end

    class << self
      def from_string(string)
        start_string, end_string = string.split('-').map { |s| s.strip }

        start_year, start_month, start_day  = start_string.split('/').map { |s| s.to_i }
        end_year, end_month, end_day        = end_string.split('/').map { |s| s.to_i }

        start_date  = Time.utc(start_year, start_month, start_day, 15, 0)
        end_date    = Time.utc(end_year, end_month, end_day, 11, 0)

        Period.new(:start_date => start_date, :end_date => end_date)
      end

      def from_file(filename)
        from_string(File.read(filename))
      end
    end
  end

  class SeasonRate < TimeSpan
    def initialize(args={})
      @rate = args.delete(:rate) || 0.0
      super(args)
    end

    attr_accessor :rate

    def is_inside?(time)
      set_time(time, 15) >= start_date && time < end_date
    end

    class << self
      def from_json(json)
        data = JSON.parse(json).values.first
        from_hash(data)
      end

      def from_hash(data)
        start_month, start_day  = data['start'].split('-')
        start_date              = Time.utc(Time.now.year, start_month, start_day, 15, 0)

        end_month, end_day      = data['end'].split('-')
        end_date                = Time.utc(Time.now.year, end_month, end_day, 11, 0)
        if end_date < start_date
          end_date = Time.utc(Time.now.year+1, end_month, end_day, 11, 0)
        end

        rate                    = data['rate'].sub(/\$/, '').to_f

        SeasonRate.new(:start_date => start_date, :end_date => end_date, :rate => rate)
      end
    end
  end

  class Rental
    ACOMMODATION_TAX = 1.0411416

    def initialize(args={})
      @name         = args.fetch(:name)
      @rate         = args.fetch(:rate, 0.0)
      @cleaning_fee = args.fetch(:cleaning_fee, 0.0)
      @seasons      = args.fetch(:seasons, [])
    end

    attr_reader :name
    attr_accessor :rate, :cleaning_fee, :seasons

    def cost(period)
      total = period.range.inject(0) { |sum, day| sum + rate_for(day) }
      ((total + cleaning_fee) * ACOMMODATION_TAX).round(2)
    end

    def rate_for(day)
      return rate if seasons.empty?

      season = seasons.find { |season| season.is_inside?(day) }
      if season
        season.rate
      else
        rate
      end
    end

    class << self
      def from_file(input_file)
        from_json(File.read(input_file))
      end

      def from_json(string)
        obj = JSON.parse(string)
        case
          when obj.is_a?(Array)
            obj.map { |h| from_hash(h) }
          when obj.is_a?(Hash)
            from_hash(obj)
          else
            raise ArgumentError, "Couldn't parse input as JSON"
        end
      end

      def from_hash(data)
        rental = Rental.new(:name => data['name'])

        if data['rate']
          rental.rate = data['rate'].sub(/\$/, '').to_f
        end

        if data['cleaning fee']
          rental.cleaning_fee = data['cleaning fee'].sub(/\$/, '').to_f
        end

        if data['seasons'] && !data['seasons'].empty?
          rental.seasons = data['seasons'].map { |h| SeasonRate.from_hash(h.values.first) }
        end

        rental
      end
    end
  end

  class CostAnalyzer
    def initialize(arguments=[])
      @period   = Period.from_file(arguments[0] || 'sample_input.txt')
      @rentals  = Rental.from_file(arguments[1] || 'sample_vacation_rentals.json')
    end

    attr_reader :period, :rentals

    def run
      rentals.each { |r| puts "#{r.name}: $#{sprintf('%.2f', r.cost(period))}" }
    end
  end
end

Reservation::CostAnalyzer.new(ARGV).run if __FILE__ == $0

