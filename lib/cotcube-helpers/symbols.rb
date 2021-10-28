# frozen_string_literal: true

module Cotcube
  # Missing top level documentation
  module Helpers

  def symbols(config: init, type: nil, symbol: nil, id: nil)
      if config[:symbols_file].nil?
        SYMBOL_EXAMPLES
      else
        CSV
          .read(config[:symbols_file], headers: %i{ id symbol ticksize power months type bcf reports format name})
          .map{|row| row.to_h }
          .map{|row| [ :ticksize, :power, :bcf ].each {|z| row[z] = row[z].to_f}; row[:format] = "%#{row[:format]}f"; row }
          .reject{|row| row[:id].nil? }
          .tap { |all| all.select!{|x| x[:type] == type} unless type.nil? }
          .tap { |all| (return all.select { |x| x[:symbol] == symbol }.first ) unless symbol.nil?  }
          .tap{ |all| (return all.select { |x| x[:id]     == id     }.first) unless     id.nil? }
      end
    end

  def micros(config: init, symbol: nil, id: nil)
    if config[:micros_file].nil?
      MICRO_EXAMPLES
    else
      CSV
        .read(config[:micros_file], headers: %i{ id symbol ticksize power months type bcf reports format name})
        .map{|row| row.to_h }
        .map{|row| [ :ticksize, :power, :bcf ].each {|z| row[z] = row[z].to_f}; row[:format] = "%#{row[:format]}f"; row }
        .reject{|row| row[:id].nil? }
        .tap{ |all| (return all.select { |x| x[:symbol] == symbol }.first) unless symbol.nil? }
        .tap{ |all| (return all.select { |x| x[:id]     == id     }.first) unless     id.nil? }
    end
  end
  end

end
