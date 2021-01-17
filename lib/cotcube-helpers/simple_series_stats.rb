# frozen_string_literal: true

module Cotcube
  # Missing top level documentation
  module Helpers
    # if given a block, :ind of base is set by block.call()
    # dim reduces the sample size by top n% and least n%, so dim of 0.5 would remove 100% of the sample
    def simple_series_stats(base:, ind: nil, dim: 0, format: '%5.2f', print: true, &block)
      raise ArgumentError, 'Need :ind of type integer' if base.first.is_a?(Array) and not ind.is_a?(Integer)
      raise ArgumentError, 'Need :ind to evaluate base' if base.first.is_a?(Hash) and ind.nil?

      dim = dim.to_f if dim.is_a? Numeric
      dim = 0 if dim==false

      raise ArgumentError, 'Expecting 0 <= :dim < 0.5' unless dim.is_a?(Float) and dim >= 0  and dim < 0.5
      raise ArgumentError, 'Expecting arity of one if block given' if block_given? and not block.arity==1

      precision = format[-1] == 'f' ? format[..-2].split('.').last.to_i : 0
      worker = base.
        tap {|b| b.map{|x| x[ind] = block.call(x) } if block.is_a? Proc }.
        map {|x| ind.nil? ? x : x[ind] }.
        compact.
        sort
      unless dim.zero?
        reductor = (base.size * dim).round
        puts reductor
        worker = worker[reductor..base.size - reductor]
        puts worker.size
      end
      result = {}

      result[:size]   =  worker.size
      result[:min]    =  worker.first
      result[:avg]    = (worker.reduce(:+) / result[:size]).round(precision+1)
      result[:lower]  =  worker[ (result[:size] * 1 / 4).round ]
      result[:median] =  worker[ (result[:size] * 2 / 4).round ]
      result[:upper]  =  worker[ (result[:size] * 3 / 4).round ]
      result[:max]    =  worker.last

      result[:output] = result.
        reject{|k,_| k == :size}.
        map{|k,v| { type: k, value: v, output: "#{k}: #{format(format, v)}".colorize(k==:avg ? :light_yellow : :white) } }.
        sort_by{|x| x[:value]}.
        map{|x| x[:output]}
      output = "[" + 
               " size: #{format '%6d', result[:size]} | ".light_white + 
               output.join(' |  ') + 
               " ]"

      puts result[:output] if print
      result
    end
  end
end
