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
  def pairwise(&block)
    raise ArgumentError, 'Array.one_by_one needs an arity of 2 (i.e. |a, b|)' unless block.arity == 2
    return [] if size <= 1

    each_with_index.map do |_, i|
      next if i.zero?

      block.call(self[i - 1], self[i])
    end.compact
  end

  alias one_by_one pairwise

  # same as pairwise, but with arity of three
  def triplewise(&block)
    raise ArgumentError, 'Array.triplewise needs an arity of 3 (i.e. |a, b, c|)' unless block.arity == 3
    return [] if size <= 2

    each_with_index.map do |_, i|
      next if i < 2

      block.call(self[i - 2], self[i - 1], self[i])
    end.compact
  end
end
