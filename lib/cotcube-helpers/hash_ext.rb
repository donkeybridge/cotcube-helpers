# frozen_string_literal: true

# Monkey patching the Ruby Core class Hash
class Hash
  def keys_to_sym
    each_key do |key|
      case self[key].class.to_s
      when 'Hash'
        self[key].keys_to_sym
      when 'Array'
        self[key].map { |el| el.is_a?(Hash) ? el.keys_to_sym : el }
      end
      self[key.to_sym] = delete(key)
    end
    self
  end
end
