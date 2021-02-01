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

# Recursively freeze self if it's Enumerable
# Supports all Ruby versions 1.8.* to 2.2.*+
module Kernel
  alias deep_freeze freeze
  alias deep_frozen? frozen?
end

# Adding deep_freeze and deep_frozen?
module Enumerable
  def deep_freeze
    unless @deep_frozen
      each(&:deep_freeze)
      @deep_frozen = true
    end
    freeze
  end

  def deep_frozen?
    !!@deep_frozen
  end
end
