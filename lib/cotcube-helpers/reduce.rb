module Cotcube
  module Helpers
    def reduce(bars: , to: nil, datelike: :datetime, &block)
      terminators = case to
                   when 1.day
                     [:last, :beginning_of_day]
                   when 1.hour
                     [:first, :beginning_of_hour]
                   else 
                     raise ArgumentError, "Currently supported are reductions to '1.hour' and '1.day'"
                   end
      determine_datelike = lambda {|ary| ary.send(terminators.first)[datelike].send(terminators.last) }
      make_new_bar = lambda do |ary, date = nil|
	result = {
          contract: ary.first[:contract],
	  symbol:   ary.first[:symbol],
          datetime: determine_datelike.call(ary),
	  day:      ary.first[:day],
	  open:     ary.first[:open],
	  high:     ary.map{|x| x[:high]}.max,
	  low:      ary.map{|x| x[:low]}.min,
	  close:    ary.last[:close],
	  volume:   ary.map{|x| x[:volume]}.reduce(:+)
	}
	result.map{|k,v| result.delete(k) if v.nil?}
	result
      end
      collector = [ ]
      final     = [ ]
      bars.each do |bar|
        if collector.empty? or block.call(collector.last, bar)
	  collector << bar
	else
          new_bar = make_new_bar.call(collector)
	  final << new_bar
	  collector = [ bar ]
	end
      end
      new_bar = make_new_bar.call(collector)
      final << new_bar
      final
    end
  end
end

