# frozen_string_literal: true

module Cotcube
  module Helpers
    # sub (should be 'subpattern', but too long) is for use in case / when statements
    #   it returns a lambda, that checks the case'd expression for matching subpattern
    #   based on the the giving minimum. E.g. 'a', 'ab' .. 'abcd' will match sub(1){'abcd'}
    #   but only 'abc' and 'abcd' will match sub(3){'abcd'}
    #
    #   The recommended use within evaluating user input, where abbreviation of incoming commands
    #   is desirable (h for hoover and hyper, what will translate to sub(2){'hoover'} and sub(2){hyper})
    #
    #   To extend functionality even more, it is possible to send a group of patterns to, like
    #   sub(2){[:hyper,:mega]}, what will respond truthy to "hy" and "meg" but not to "m" or "hypo"
    def sub(minimum = 1)
      pattern = yield
      case pattern
      when String, Symbol, NilClass
        pattern = pattern.to_s
        lambda do |x|
          return false if x.nil? || (x.size < minimum)

          return ((pattern =~ /^#{x}/i).nil? ? false : true)
        end
      when Array
        pattern.map do |x|
          unless [String, Symbol, NilClass].include? x.class
            raise TypeError, "Unsupported class '#{x.class}' for '#{x}'in pattern '#{pattern}'."
          end
        end
        lambda do |x|
          pattern.each do |sub|
            sub = sub.to_s
            return false if x.size < minimum

            result = ((sub =~ /^#{x}/i).nil? ? false : true)
            return true if result
          end
          return false
        end
      else
        raise TypeError, "Unsupported class #{pattern.class} in Cotcube::Core::sub"
      end
    end
  end
end
