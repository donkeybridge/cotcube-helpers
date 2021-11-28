module Cotcube
  module Helpers

    class ExpirationMonth
      attr_accessor *%i[ asset month year holidays stencil ]
      def initialize( contract: )
        a,b,c,d,e = contract.chars
        @asset  = [ a, b ].join
        if %w[ GG DL BJ GE VI ] 
          puts "Denying to calculate expiration for #{@asset}".light_red
          return
        end
        @month  = MONTHS[c] + offset
        @month -= 1 if %w[ CL HO NG RB SB].include? @asset
        @month += 1 if %w[ ].include? @asset
        @month += 12 if month < 1
        @month -= 12 if month > 12
        @year   = [ d, e ].join.to_i
        @year  += year > 61 ? 1900 : 2000
        @holidays = CSV.read("/var/cotcube/bardata/holidays.csv").map{|x| DateTime.parse(x[0]).to_date}.select{|x| x.year == @year }
        @stencil  = [ Date.new(@year, @month, 1) ] 
        end_date = Date.new(@year, @month + 1, 1 )
        while (next_date = @stencil.last + 1) < end_date
          @stencil << next_date
        end
        @stencil.reject!{|x| [0,6].include?(x.wday) or @holidays.include? x}
      end
    end

  end
end
