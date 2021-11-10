module Cotcube
  module Helpers
    def get_ib_contract(contract)
      symbol = contract[..1]
      # TODO consider file location to be found in configfile
      filepath =  '/etc/cotcube/ibsymbols/'
      result = YAML.load(File.read( "#{filepath}/#{symbol}.yml"))[contract].transform_keys(&:to_sym) rescue nil
      result.nil? ? update_ib_contracts(symbol: contract[..1]) : (return result)
      YAML.load(File.read( "#{filepath}/#{symbol}.yml"))[contract].transform_keys(&:to_sym) rescue nil
    end

    def update_ib_contracts(symbol: nil)
      begin
        client = DataClient.new
        (Cotcube::Helpers.symbols + Cotcube::Helpers.micros).each do |sym|

          # TODO: consider file location to be located in config
          file = "/etc/cotcube/ibsymbols/#{sym[:symbol]}.yml"

          # TODO: VI publishes weekly options which dont match, the 3 others need multiplier enabled to work
          next if %w[ DY TM SI VI ].include? sym[:symbol]
          next if symbol and sym[:symbol] != symbol
          begin
            if File.exist? file
              next if Time.now - File.mtime(file) < 5.days
              data = nil
              data = YAML.load(File.read(file))
            else
              data = {}
            end
            p file
            %w[ symbol sec_type exchange multiplier ticksize power internal ].each {|z| data.delete z}
            raw   = client.get_contracts(symbol: sym[:symbol])
            reply = JSON.parse(raw)['result']
            reply.each do |set|
              contract = translate_ib_contract set['local_symbol']
              data[contract] ||= set
            end
            keys = data.keys.sort_by{|z| z[2]}.sort_by{|z| z[-2..] }.select{|z| z[..1] == sym[:symbol] }
            data = data.slice(*keys)
            File.open(file, 'w'){|f| f.write(data.to_yaml) }
          rescue Exception => e
            puts e.full_message
            p sym
            binding.irb
          end
        end
      ensure 
        client.stop
        true
      end
    end
  end
end

