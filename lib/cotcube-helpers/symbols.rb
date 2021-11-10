# frozen_string_literal: true

module Cotcube
  # Missing top level documentation
  module Helpers

    SYMBOL_HEADERS = %i[ id symbol ib_symbol internal exchange currency ticksize power months type bcf reports format name ]

    def symbols(config: init, **args)
      if config[:symbols_file].nil?
        SYMBOL_EXAMPLES
      else
        CSV
          .read(config[:symbols_file], headers: SYMBOL_HEADERS)
          .map{|row| row.to_h }
          .map{|row|
            [ :ticksize, :power, :bcf ].each {|z| row[z] = row[z].to_f}
            row[:format] = "%#{row[:format]}f"
            row[:currency] ||= 'USD'
            row[:multiplier] = (row[:power] / row[:ticksize]).round(8)
            row
          }
          .reject{|row| row[:id].nil? }
          .tap{ |all|
            args.keys.each { |header|
              unless SYMBOL_HEADERS.include? header
                puts "WARNING in Cotcube::Helpers.symbols: '#{header}' is not a valid symbol header. Skipping..."
                next
              end
              all.select!{|x| x[header] == args[header]} unless args[header].nil?
              return all.first if all.size == 1
            }
            return all
          }
      end
    end

    def micros(config: init, **args)
      if config[:micros_file].nil?
        MICRO_EXAMPLES
      else
        CSV
          .read(config[:micros_file], headers: SYMBOL_HEADERS)
          .map{|row| row.to_h }
          .map{|row|
            [ :ticksize, :power, :bcf ].each {|z| row[z] = row[z].to_f }
            row[:format] = "%#{row[:format]}f"
            row[:currency] ||= 'USD'
            row[:multiplier] = (row[:power] / row[:ticksize]).round(8)
            row
          }
          .reject{|row| row[:id].nil? }
          .tap{ |all|
            args.keys.each { |header|
             unless SYMBOL_HEADERS.include? header
                puts "WARNING in Cotcube::Helpers.micros: '#{header}' is not a valid symbol header. Skipping..."
                next
              end
              all.select!{|x| x[header] == args[header]} unless args[header].nil?
              return all.first if all.size == 1
            }
            return all
          }
      end
    end

    def translate_ib_contract(contract)
      short = contract.split(" ").size == 1
      sym_a = contract.split(short ? '' : ' ')
      year  = sym_a.pop.to_i + (short ? 20 : 0)
      if short and sym_a[-1].to_i > 0 
        year = year - 20 + sym_a.pop.to_i * 10
      end
      month = short ? sym_a.pop : LETTERS[sym_a.pop]
      sym   = Cotcube::Helpers.symbols(internal: sym_a.join)[:symbol] rescue nil
      sym ||= Cotcube::Helpers.micros(internal: sym_a.join)[:symbol] rescue nil
      sym.nil? ? false : "#{sym}#{month}#{year}"
    end

  end

end
