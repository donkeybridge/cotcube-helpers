module Tritangent
  module Helpers
    include ::Tod
    #Notice the first use of keyword arguments here ;)
    def fill_x (base:, discretion:, time:, attr:, maintenance: nil, zone: nil)
      zone ||= case base[0][time].zone
               when 'CDT','CT','CST'
                 "America/Chicago"
               when 'EDT', 'ET', 'EST'
                 "AMerica/New_York"
               else
                 "UTC"
               end
                 
      maintenance ||= case zone
                      when "America/Chicago"
                        { 0 => Shift.new(Tod::TimeOfDay.new( 0), Tod::TimeOfDay.new(17), true),
  			  1 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
			  2 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
		  	  3 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
		 	  4  => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
			  5 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new( 0), true)
                        }
                      when "America/New_York"
                        { 0 => Tod::Shift.new(Tod::TimeOfDay.new( 0), Tod::TimeOfDay.new(17), true),
                          1 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
                          2 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
                          3  => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
                          4 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new(17), true),
                          5 => Tod::Shift.new(Tod::TimeOfDay.new(16), Tod::TimeOfDay.new( 0), true)
                        }
                      else
                        raise "Tritangent::Helpers.fill_x needs :maintenance or :zone"
                      end

      tz = Time.find_zone zone
      exchange_open = lambda do |t0|
        current_week_day = t0.wday
        return false if current_week_day == 6
        not maintenance[current_week_day].include?(Tod::TimeOfDay(t0.in_time_zone(zone)))
      end
      result = [] # [ { time => base.first[time], attr => base.first[attr] } ]
      i = 0
      timer = base.first[time]
      while not base[i].nil?
        if timer == base[i][time] 
          result << {  time => timer, attr => base[i][attr] } 
          i += 1
        else 
          result << {  time => timer } if exchange_open.call(timer)
        end
        timer += discretion
      end
      result
    end
  end
end
