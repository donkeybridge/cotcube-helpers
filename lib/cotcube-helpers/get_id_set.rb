# frozen_string_literal: true

module Cotcube
  module Helpers

    def get_id_set(symbol: nil, id: nil, contract: nil, config: init)
      contract = contract.to_s.upcase if contract.is_a? Symbol
      id       =       id.to_s.upcase if       id.is_a? Symbol
      symbol   =   symbol.to_s.upcase if   symbol.is_a? Symbol

      if contract.is_a?(String) && (contract.length == 5)
        c_symbol = contract[0..1]
        if (not symbol.nil?) && (symbol != c_symbol)
          raise ArgumentError,
                "Mismatch between given symbol #{symbol} and contract #{contract}"
        end

        symbol = c_symbol
      end

      unless symbol.nil?
        sym = symbols.select { |s| s[:symbol] == symbol.to_s.upcase }.first
        if sym.nil? || sym[:id].nil?
          raise ArgumentError,
                "Could not find match in #{config[:symbols_file]} for given symbol #{symbol}"
        end
        raise ArgumentError, "Mismatching symbol #{symbol} and given id #{id}" if (not id.nil?) && (sym[:id] != id)

        return sym
      end
      unless id.nil?
        sym = symbols.select { |s| s[:id] == id.to_s }.first
        if sym.nil? || sym[:id].nil?
          raise ArgumentError,
                "Could not find match in #{config[:symbols_file]} for given id #{id}"
        end
        return sym
      end
      raise ArgumentError, 'Need :id, :symbol or valid :contract '
    end
  end
end

