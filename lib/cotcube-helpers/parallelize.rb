module Cotcube
  module Helpers

    def parallelize(ary, opts = {}, &block)
      processes =           opts[:processes].nil? ? 1  : opts[:processes]
      threads_per_process = opts[:threads  ].nil? ? 1  : opts[:threads]
      progress =            opts[:progress ].nil? ? "" : opts[:progress]
      chunks = [] 
      if processes == 0 or processes == 1
        r = Parallel.map(ary, in_threads: threads_per_process) {|u| v = yield(u); v}
      elsif [0,1].include?(threads_per_process)
        r = Parallel.map(ary, in_processes: processes) {|u| v = yield(u)}
      else
        ary.each_slice(threads_per_process) {|chunk| chunks << chunk }
        if progress == "" 
          r = Parallel.map(chunks, :in_processes => processes) do |chunk|
            Parallel.map(chunk, in_threads: threads_per_process) do |unit|
              yield(unit) 
            end
          end
        else
          r = Parallel.map(ary, :progress => progress, :in_processes => processes) do |chunk|
            Parallel.map(chunk, in_threads: threads_per_process) do |unit|
              yield(unit)
            end
          end
        end
      end
      return r
    end

  end
end
