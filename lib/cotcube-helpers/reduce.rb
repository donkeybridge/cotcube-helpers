# frozen_string_literal: true

module Cotcube
  # Missing top level documentation
  module Helpers
    def reduce(bars:, to: nil, date_alike: :datetime, &block)
      case to
      when :days
        terminators = %i[last daily beginning_of_day]
        block = proc { |c, b| c[:day] == b[:day] } unless block_given?
      when :hours
        terminators = %i[first hours beginning_of_hour]
        block = proc { |c, b| c[:day] == b[:day] and c[:datetime].hour == b[:datetime].hour } unless block_given?
      when :weeks
        terminators = %i[first weeks beginning_of_week]
        block = proc { |a, b| a[:datetime].to_datetime.cweek == b[:datetime].to_datetime.cweek } unless block_given?
      when :months
        terminators = %i[first months beginning_of_month]
        block = proc { |a, b| a[:datetime].to_datetime.month == b[:datetime].to_datetime.month } unless block_given?
      else
        raise ArgumentError, 'Currently supported are reductions to :hours, :days, :weeks, :months '
      end
      determine_date_alike = ->(ary) { ary.send(terminators.first)[date_alike].send(terminators.last) }
      make_new_bar = lambda do |ary, _date = nil|
        result = {
          contract: ary.first[:contract],
          symbol: ary.first[:symbol],
          datetime: determine_date_alike.call(ary),
          day: ary.first[:day],
          open: ary.first[:open],
          high: ary.map { |x| x[:high] }.max,
          low: ary.map { |x| x[:low] }.min,
          close: ary.last[:close],
          volume: ary.map { |x| x[:volume] }.reduce(:+),
          type: terminators[1]
        }
        result.map { |k, v| result.delete(k) if v.nil? }
        result
      end
      collector = []
      final     = []
      bars.each do |bar|
        if collector.empty? || block.call(collector.last, bar)
          collector << bar
        else
          new_bar = make_new_bar.call(collector)
          final << new_bar
          collector = [bar]
        end
      end
      new_bar = make_new_bar.call(collector)
      final << new_bar
      final
    end
  end
end
