# frozen_string_literal: true

# Monkey patching the Ruby Core class Array
class Array
  # returns nil if the compacted array is empty, otherwise returns the compacted array
  def compact_or_nil(*_args)
    return nil if compact == []

    yield compact
  end

  # sorts by a given attribute and then returns groups of where this attribute is equal
  # .... seems like some_array.group_by(&attr).values
  def split_by(attrib)
    res = []
    sub = []
    sort_by(&attrib).each do |elem|
      if sub.empty? || (sub.last[attrib] == elem[attrib])
        sub << elem
      else
        res << sub
        sub = [elem]
      end
    end
    res << sub
    res
  end

  # This method iterates over an Array by calling the given block on all 2 consecutive elements
  # it returns a Array of self.size - 1
  #
  def pairwise(ret=nil, empty: nil, &block)
    raise ArgumentError, 'Array.one_by_one needs an arity of 2 (i.e. |a, b|)' unless block.arity == 2
    raise ArgumentError, 'Each element of Array should respond to []=, at least the last one fails.' if not ret.nil? and not  self.last.respond_to?(:[]=)
    return empty ||= [] if size <= 1

    each_index.map do |i|
      next if i.zero?

      r = block.call(self[i - 1], self[i])
      ret.nil?  ? r : (self[i][ret] = r)
    end.compact
  end

  alias one_by_one pairwise

  # same as pairwise, but with arity of three
  def triplewise(ret=nil, &block)
    raise ArgumentError, 'Array.triplewise needs an arity of 3 (i.e. |a, b, c|)' unless block.arity == 3
    raise ArgumentError, 'Each element of Array should respond to []=, at least the last one fails.' if not ret.nil? and not self.last.respond_to?(:[]=)
    return [] if size <= 2

    each_index.map do |i|
      next if i < 2

      r = block.call(self[i - 2], self[i - 1], self[i])
      ret.nil?  ? r : (self[i][ret] = r)
    end.compact
  end

  # selects all elements from array that fit in given ranges.
  # if :attr is given, selects all elements, where elem[:attr] fit
  # raises if elem.first[attr].nil?
  def select_within(ranges:, attr: nil, &block)
    unless attr.nil? || first[attr]
      raise ArgumentError,
        "At least first element of Array '#{first}' does not contain attr '#{attr}'!"
    end
    raise ArgumentError, 'Ranges should be an Array or, more precisely, respond_to :map' unless ranges.respond_to? :map
    raise ArgumentError, 'Each range in :ranges should respond to .include!' unless ranges.map do |x|
      x.respond_to? :include?
    end.reduce(:&)

    select do |el|
      value = attr.nil? ? el : el[attr]
      ranges.map do |range|
        range.include?(block.nil? ? value : block.call(value))
      end.reduce(:|)
    end
  end

  def select_right_by(inclusive: false, exclusive: false, initial: [], &block)
    # unless range.is_a? Range and
    #       (range.begin.nil? or range.begin.is_a?(Integer)) and
    #       (range.end.nil? or range.end.is_a?(Integer))
    #  raise ArgumentError, ":range, if given, must be a range of ( nil|Integer..nil|Integer), got '#{range}'"
    # end

    raise ArgumentError, 'No block given.' unless block.is_a? Proc

    inclusive = true unless exclusive
    if inclusive && exclusive
      raise ArgumentError,
        "Either :inclusive or :exclusive must remain falsey, got '#{inclusive}' and '#{exclusive}'"
    end

    index = find_index { |obj| block.call(obj) }

    self[((inclusive ? index : index + 1)..)]
  end

  def elem_raises?(&block)
    raise ArgumentError, "Must provide a block." unless block_given?
    raise ArgumentError, "Block must have arity of 1." unless block.arity == 1
    map do |elem|
      begin
        block.call(elem)
        false
      rescue
        elem
      end
    end.reject{|z| z.is_a? FalseClass }.tap{|z| z.empty? ? (return false) : (return z)}
  end

  def deep_dup
    map do |el|
      case el
      when Hash, Array
        el.deep_dup
      else
        el.dup
      end
    end
  end

end
