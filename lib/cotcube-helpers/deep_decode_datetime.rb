module Cotcube
  module Helpers
    VALID_DATETIME_STRING = lambda {|str| str.is_a?(String) and [10,25,29].include?(str.length) and str.count("^0-9:TZ+-= ").zero? }

    def deep_decode_datetime(data, zone: DateTime)
      case data
      when nil;    nil
      when VALID_DATETIME_STRING
        res = nil
        begin
          res = zone.parse(data)
        rescue ArgumentError
          data
        end
        [ DateTime, ActiveSupport::TimeWithZone ].include?(res.class) ? res : data
      when Array; data.map!              { |d| deep_decode_datetime(d, zone: zone) }
      when Hash;  data.transform_values! { |v| deep_decode_datetime(v, zone: zone) }
      else;       data
      end
    end

    module_function :deep_decode_datetime
  end
end

