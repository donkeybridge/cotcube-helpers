class Time
  def to_centi
    (self.to_f * 1000.0).to_i
  end

  def to_part(x=100)
    (self.to_f * x.to_f).to_i % x
  end
end


class Date
  def abbr_dayname
    ABBR_DAYNAMES[self.wday]
  end

  def to_string
    self.strftime("%Y-%m-%d")
  end

  def to_timestring
    self.strftime("%Y-%m-%d-%H-%M-%S")
  end

end

class String
  def to_date
    Date::strptime(self, "%Y-%m-%d")
  end

  def to_time
    DateTime::strptime(self, "%s")
  end
end

class Integer
  def to_tz
    return "+0000" if self == 0
    sign    = self > 0 ? "+" : "-"
    value   = self.abs
    hours   = (value / 3600.to_f).floor
    minutes = ((value - 3600 * hours) / 60).floor
    "#{sign}#{hours>9 ? "" : "0"}#{hours}#{minutes<10 ? "0" : "" }#{minutes}"
  end

  def to_tod(zone="UTC") 
    self.to_time
      #in_time_zone(zone).
      #to_time_of_day
  end

  def to_tod_i
    (self / 100).to_time.strftime("%H%M%S").to_i
  end

  def to_date
    Date::strptime(self.to_s, "%s")
  end

  def to_time
    DateTime.strptime(self.to_s, "%s")
  end

end

