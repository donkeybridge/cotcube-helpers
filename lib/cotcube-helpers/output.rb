module Cotcube
  module Helpers

    def instance_inspect(obj, keylength: 20, &block)
      obj.instance_variables.map do |var| 
        if block_given?
          block.call(var, obj.instance_variable_get(var))
        else
          puts "#{format "%-#{keylength}s", var
                         }: #{obj.instance_variable_get(var).inspect.scan(/.{1,120}/).join( "\n" + ' '*(keylength+2)) 
                         }" 
        end
      end
    end

    module_function :instance_inspect

  end
end

