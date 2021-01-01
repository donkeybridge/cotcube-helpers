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
