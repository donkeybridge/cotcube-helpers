#frozen_string_literal: true

module Cotcube
  module Helpers
    SYMBOL_EXAMPLES = [
      { id: '13874U', symbol: 'ES', ib_symbol: 'ES', internal: 'ES', exchange: 'GLOBEX', currency: 'USD', ticksize: 0.25, power: 12.5, months: 'HMUZ', bcf: 1.0, reports: 'LF', format: '8.2f', name: 'S&P 500 MICRO' },
      { id: '209747', symbol: 'NQ', ib_symbol: 'NQ', internal: 'NQ', exchange: 'GLOBEx', currency: 'USD', ticksize: 0.25, power: 5.0,  monhts: 'HMUZ', bcf: 1.0, reports: 'LF', format: '8.2f', name: 'NASDAQ 100 MICRO' }
    ].freeze

    MICRO_EXAMPLES = [
      { id: '13874U', symbol: 'ET', ib_symbol: 'MES', internal: 'MES', exchange: 'GLOBEX', currency: 'USD', ticksize: 0.25, power: 1.25, months: 'HMUZ', bcf: 1.0, reports: 'LF', format: '8.2f', name: 'MICRO S&P 500 MICRO' },
      { id: '209747', symbol: 'NM', ib_symbol: 'MNQ', internal: 'MNQ', exchange: 'GLOBEX', currency: 'USD', ticksize: 0.25, power: 0.5,  monhts: 'HMUZ', bcf: 1.0, reports: 'LF', format: '8.2f', name: 'MICRO NASDAQ 100 MICRO' }
    ].freeze

    COLORS         = %i[light_red light_yellow light_green red yellow green cyan magenta blue].freeze

    MONTH_COLOURS  = { 'F' => :cyan,  'G' => :green,   'H' => :light_green,
                       'J' => :blue,  'K' => :yellow,  'M' => :light_yellow,
                       'N' => :cyan,  'Q' => :magenta, 'U' => :light_magenta,
                       'V' => :blue,  'X' => :red,     'Z' => :light_red }.freeze

    MONTHS         = { 'F' => 1,  'G' =>  2, 'H' =>  3,
                       'J' => 4,  'K' =>  5, 'M' =>  6,
                       'N' => 7,  'Q' =>  8, 'U' =>  9,
                       'V' => 10, 'X' => 11, 'Z' => 12,
                       1 => 'F',  2 => 'G',  3 => 'H',
                       4 => 'J',  5 => 'K',  6 => 'M',
                       7 => 'N',  8 => 'Q',  9 => 'U',
                       10 => 'V', 11 => 'X', 12 => 'Z' }.freeze


    CHICAGO  = Time.find_zone('America/Chicago')
    NEW_YORK = Time.find_zone('America/New_York')
    BERLIN   = Time.find_zone('Europe/Berlin')

    DATE_FMT = '%Y-%m-%d'

    # Simple mapper to get from MONTH to LETTER
    LETTERS = { "JAN"=> "F", "FEB"=> "G", "MAR"=> "H",
                "APR"=> "J", "MAY"=> "K", "JUN"=> "M",
                "JUL"=> "N", "AUG"=> "Q", "SEP"=> "U",
                "OCT"=> "V", "NOV"=> "X", "DEC"=> "Z" }

  end
end

