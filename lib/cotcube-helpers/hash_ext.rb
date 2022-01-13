# frozen_string_literal: true

# Monkey patching the Ruby Core class Hash
class Hash
  def keys_to_sym!
    self.keys.each do |key|
      case self[key].class.to_s
      when 'Hash'
        self[key].keys_to_sym!
      when 'Array'
        self[key].map { |el| el.is_a?(Hash) ? el.keys_to_sym! : el }
      end
      self["#{key}".to_sym] = delete(key)
    end
    self
  end

  # a group_hash was created from an array by running group_by
  # to reduce a group_hash, the given block is applied to each array of the hash
  # if its not an array value, the block will auto-yield nil
  def reduce_group(&block)
    raise ArgumentError, 'No block given' unless block_given?
    map do |key,value|
      case value
      when Array
        [key, (block.call(value) rescue nil) ]
      else
        [key, nil]
      end
    end.to_h
  end

  def deep_dup
    map do |k,v|
      case v
      when Hash, Array
        [k, v.deep_dup]
      else
        [k, v.dup]
      end
    end.to_h
  end
end
