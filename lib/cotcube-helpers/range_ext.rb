class Range
  def to_time_intervals(timezone: Time.find_zone('America/Chicago'), step:, ranges: nil)

    raise ArgumentError, ":step must be a 'ActiveSupport::Duration', like '15.minutes', but '#{step}' is a '#{step.class}'" unless step.is_a? ActiveSupport::Duration

    valid_classes = [ ActiveSupport::TimeWithZone, Time, Date, DateTime ]
    raise "Expecting 'ActiveSupport::TimeZone' for :timezone, got '#{timezone.class}" unless timezone.is_a? ActiveSupport::TimeZone
    starting = self.begin
    ending   = self.end
    starting = timezone.parse(starting) if starting.is_a? String
    ending   = timezone.parse(ending)   if ending.is_a?   String
    raise ArgumentError, ":self.begin seems not to be proper time value: #{starting} is a #{starting.class}" unless valid_classes.include? starting.class
    raise ArgumentError, ":self.end seems not to be proper time value: #{ending} is a #{ending.class}" unless valid_classes.include? ending.class

    ##### The following is the actual big magic line: 
    # 
    result    = (starting.to_time.to_i..ending.to_time.to_i).step(step).to_a.map{|x| timezone.at(x)}
    #
    ####################<3


    # with step.to_i >= 86400 we are risking stuff like 25.hours to return bogus
    # also notice: When using this with swaps, you will loose 1 hour (#f**k_it)
    #
    # eventually, for dailies and above, return M-F default, return S-S when forced by empty ranges
    return result.select{|x| (not ranges.nil? and ranges.empty?) ? true : (not [6,0].include?(x.wday)) } if step.to_i >= 86400

    # sub-day is checked for DST and filtered along provided ranges
    starting_with_dst = result.first.dst?
    seconds_since_sunday_morning = lambda {|x| x.wday * 86400 + x.hour * 3600 + x.min * 60 + x.sec}
    ranges ||= [
      61200..143999,  
      147600..230399,
      234000..316799,
      320400..403199,
      406800..489599
    ]

    # if there was a change towards daylight saving time, substract 1 hour, otherwise add 1 hour
    result.map! do |time|
      if    not starting_with_dst and     time.dst?
	time - 3600
      elsif     starting_with_dst and not time.dst?
	time + 3600
      else
	time
      end
    end
    return result if ranges.empty? 
    result.select{|x| ranges.map{|r| r.include? seconds_since_sunday_morning.call(x)}.reduce(:|) }
  end
end
