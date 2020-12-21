module Cotcube
  module Helpers

    def parallelize(ary, processes: 1, threads: 1, progress: "", &block)
      chunks = [] 
      if [0,1].include? processes 
        result = Parallel.map(ary, in_threads: threads) {|u| v = yield(u); v}
      elsif [0,1].include?(threads)
        result = Parallel.map(ary, in_processes: processes) {|u| v = yield(u)}
      else
        ary.each_slice(threads) {|chunk| chunks << chunk }
        if progress == "" 
          result = Parallel.map(chunks, :in_processes => processes) do |chunk|
            Parallel.map(chunk, in_threads: threads) do |unit|
              yield(unit) 
            end
          end
        else
          result = Parallel.map(chunks, :progress => progress, :in_processes => processes) do |chunk|
            Parallel.map(chunk, in_threads: threads) do |unit|
              yield(unit)
            end
          end
        end
      end
      result
    end

  end
end
