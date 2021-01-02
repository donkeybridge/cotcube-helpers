# frozen_string_literal: true

# TODO: Missing top level documentation!
module Cotcube
  # TODO: Missing top level documentation!
  module Helpers
    def parallelize(ary, processes: 1, threads: 1, progress: '', &block)
      chunks = []
      if [0, 1].include? processes
        result = Parallel.map(ary, in_threads: threads, &block)
      elsif [0, 1].include? threads
        result = Parallel.map(ary, in_processes: processes, &block)
      else
        ary.each_slice(threads) { |chunk| chunks << chunk }
        result = if progress == ''
                   Parallel.map(chunks, in_processes: processes) do |chunk|
                     Parallel.map(chunk, in_threads: threads, &block)
                   end
                 else
                   Parallel.map(chunks, progress: progress, in_processes: processes) do |chunk|
                     Parallel.map(chunk, in_threads: threads, &block)
                   end
                 end
      end
      result
    end
  end
end
