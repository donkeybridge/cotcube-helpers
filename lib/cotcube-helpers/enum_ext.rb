# frozen_string_literal: true

# Monkey patching the Ruby Core class Enumerator
class Enumerator
  def shy_peek
    begin
      ret = peek
    rescue StandardError
      ret = nil
    end
    ret
  end
end
