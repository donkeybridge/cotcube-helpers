# frozen_string_literal: true

# Monkey patching the Ruby Core class Range
class Range
  def to_time_intervals(step:, timezone: Time.find_zone('America/Chicago'), ranges: nil)
    unless step.is_a? ActiveSupport::Duration
      raise ArgumentError,
            ":step must be a 'ActiveSupport::Duration', like '15.minutes', but '#{step}' is a '#{step.class}'"
    end
    raise ArgumentError, "Sorry, currently supporting only 15.minutes, 1.hour, 1.day as :step" unless [15.minutes, 60.minutes, 1.hour, 1.day].include? step

    valid_classes = [ActiveSupport::TimeWithZone, Time, Date, DateTime]
    unless timezone.is_a? ActiveSupport::TimeZone
      raise "Expecting 'ActiveSupport::TimeZone' for :timezone, got '#{timezone.class}"
    end

    starting = self.begin
    ending   = self.end
    starting = timezone.parse(starting) if starting.is_a? String
    ending   = timezone.parse(ending)   if ending.is_a?   String
    unless valid_classes.include? starting.class
      raise ArgumentError,
            ":self.begin seems not to be proper time value: #{starting} is a #{starting.class}"
    end
    unless valid_classes.include? ending.class
      raise ArgumentError,
            ":self.end seems not to be proper time value: #{ending} is a #{ending.class}"
    end

    # here sub-day and super-day need to be distinguished, as they react differently to daylight time
    # for super-day, just return an array containing all calendar days
    if step.to_i >= 1.day
      return (starting.to_date..ending.to_date).to_a.map{|x| x.to_datetime}
    else

      ##### The following is the actual big magic line, as it creates the raw target array:
      #
      result = (starting.to_time.to_i..ending.to_time.to_i).step(step).to_a.map { |x| timezone.at(x) }
      #
      # ###################<3##


      # sub-day is checked for DST and filtered along provided ranges
      # noinspection RubyNilAnalysis
      starting_with_dst = result.first.dst?

      # The following lambda is completely misplaces here.
      # It should probably relocated to Cotcube::Bardata
      # NOTE: In this current version 12 belongs to it succeeding hour
      #       i.e. 12am is right before 1am and 12pm right before 1pm
      convert_to_sec_since = lambda do |clocking|
        from_src, to_src = clocking.split(' - ')
        regex = /^(?<hour>\d+):(?<minute>\d+)(?<morning>[pa]).?m.*/

        from = from_src.match(regex)
        to   = to_src.match(regex)

        from_i = from[:hour].to_i * 3600 + from[:minute].to_i * 60 + (from[:morning] == 'a' ? 2 : 1) * 12 * 3600
        to_i = to[:hour].to_i * 3600 + to[:minute].to_i * 60 + (to[:morning] == 'a' ? 2 : 3) * 12 * 3600

        (0...5).to_a.map { |i| [from_i + i * 24 * 3600, to_i + i * 24 * 3600] }
      end
      convert_to_sec_since.call('9:00a.m - 5:00p.m.')

      ranges ||= [
        61_200...144_000,   # Sun 5pm .. Mon 4pm
        147_600...230_400,  # Mon 5pm .. Tue 4pm
        234_000...316_800,  # ...
        320_400...403_200,
        406_800...489_600
      ]

      # if there was a change towards daylight saving time, subtract 1 hour, otherwise add 1 hour
      result.map! do |time|
        if (not starting_with_dst) && time.dst?
          time - 3600
        elsif starting_with_dst && (not time.dst?)
          time + 3600
        else
          time
        end
      end

      result.select_within(ranges: ranges) { |x| x.to_datetime.to_seconds_since_monday_morning }
    end
  end
end
