# frozen_string_literal: true

# Monkey patching the Ruby class DateTime
class DateTime
  # based on the fact that sunday is 'wday 0' plus that trading week starts
  #   sunday 0:00 (as trading starts sunday 5pm CT to fit tokyo monday morning)
  def to_seconds_since_sunday_morning
    wday * 86_400 + hour * 3600 + min * 60 + sec
  end

  alias to_sssm to_seconds_since_sunday_morning
end

class Date

  # creates a range of 2 dates, of the given calendar week, Monday to Sunday
  def self.cw( week: , year: Date.today.year )
    form = '%Y %W %w'
    build_range = lambda {|w|
      begin
        ( DateTime.strptime("#{year} #{w} 1", form).to_date..
          DateTime.strptime("#{year} #{w} 0", form).to_date)
      rescue
        # beyond Dec 31st #strptime must be called with cw:0 to keep it working
        ( DateTime.strptime("#{year} #{w} 1", form).to_date..
          DateTime.strptime("#{year+1} 0  0", form).to_date)
      end
    }
    case week
    when :current
      build_range.call(Date.today.cweek)
    when :last
      wday = Date.today.wday
      build_range.call((Date.today - (wday.zero? ? 7 : wday)).cweek)
    when Integer
      raise ArgumentError, "'#{week}' is not supported as calendar week, choose from (1..53)" if week <= 0 or week > 53
      build_range.call(week)
    else
      raise ArgumentError, "'#{week}' is not a supported format for calendar week"
    end
  end
end
