# encoding: utf-8

require 'bigdecimal'

module Trade

  module DuckTyping
    private

    def to_bigdecimal(value)
      case value
        when BigDecimal
          value
        else
          BigDecimal.new(value.to_s)
      end
    end
  end

  module ExchangeRates
    def self.extended(object)
      object.instance_variable_set(:@exchange_rates, [])
    end

    def exchange_rates
      @exchange_rates
    end

    def find_rate(rate)
      exchange_rates.find { |r| r == rate }
    end

    def has_rate?(rate)
      !!find_rate(rate)
    end

    def add_rate(rate)
      @exchange_rates << rate unless has_rate?
    end
  end

  class Money
    include DuckTyping

    extend ExchangeRates

    def initialize(amount, currency='USD')
      @amount   = to_bigdecimal(amount)
      @currency = currency
    end

    attr_reader :currency, :amount

    def amount=(value)
      @amount = to_bigdecimal(amount)
    end
  end

  class Rate
    include DuckTyping

    def initialize(from, to, rate)
      @from = from
      @to   = to
      @rate = to_bigdecimal(rate)
    end

    attr_accessor :from, :to

    attr_reader :rate

    def rate=(value)
      @rate = to_bigdecimal(value)
    end

    def convert(value)
      to_bigdecimal(value) * @rate
    end

    def inverse
      Rate.new(@to, @from, 1 / @rate)
    end

    def to_key
      "#{@from}-#{@to}"
    end

    def to_s
      "(#{to_key})@#{@rate.to_s('f')}"
    end
  end

  class Transaction
    def initialize(store, sku, amount=Money.new(1, 'USD'))
      @store  = store
      @sku    = sku
      @amount = amount
    end

    attr_reader :store, :sku, :amount
  end
end

## test

aud_to_cad = Trade::Rate.new('CAD', 'AUD', 1.0079)
cad_to_usd = Trade::Rate.new('CAD', 'USD', 1.0090)

a = aud_to_cad.convert(cad_to_usd.convert(19.68)).round(2, BigDecimal::ROUND_HALF_EVEN)
b = aud_to_cad.convert(cad_to_usd.convert(58.58)).round(2, BigDecimal::ROUND_HALF_EVEN)
c = BigDecimal.new('54.64').round(2, BigDecimal::ROUND_HALF_EVEN)

puts (a+b+c).round(2, BigDecimal::ROUND_HALF_EVEN).to_s('f')
