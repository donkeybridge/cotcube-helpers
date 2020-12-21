module Candlestick_Recognition

  extend self

  def candles(candles, debug = false)
    candles.each_with_index do |bar, i| 
      # rel simply sets a grace limit based on the full height of the bar, so we won't need to use the hard limit of zero
      begin 
        rel  = (bar[:high] - bar[:low]) * 0.1
      rescue 
        puts "Warning, found inappropriate bar".light_white + " #{bar}"
        raise
      end
      bar[:rel]        = rel

      bar[:upper]      = [bar[:open], bar[:close]].max
      bar[:lower]      = [bar[:open], bar[:close]].min
      bar[:bar_size]   = (bar[:high] - bar[:low])
      bar[:body_size]       = (bar[:open] - bar[:close]).abs
      bar[:lower_wick] = (bar[:lower] - bar[:low])
      bar[:upper_wick] = (bar[:high] - bar[:upper])
      bar.each{|k,v| bar[k] = v.round(8) if v.is_a? Float}

      # a doji's open and close are same (or only differ by rel)
      bar[:doji]    = true if bar[:body_size] <= rel and bar[:dist] >= 3
      bar[:tiny]    = true if bar[:dist] <= 5

      next if bar[:tiny]

      bar[:bullish]  = true if not bar[:doji] and bar[:close] > bar[:open]
      bar[:bearish]  = true if not bar[:doji] and bar[:close] < bar[:open]

      bar[:spinning_top] = true if bar[:body_size]       <= bar[:bar_size] / 4 and 
        bar[:lower_wick] >= bar[:bar_size] / 4 and
        bar[:upper_wick] >= bar[:bar_size] / 4

      # a marubozu open at high or low and closes at low or high
      bar[:marubozu] = true if bar[:upper_wick] < rel and bar[:lower_wick] < rel

      # a bar is considered bearish if it has at least a dist of 5 ticks and it's close it near high (low resp)
      bar[:bullish_close] = true if (bar[:high] - bar[:close]) <= rel and not bar[:marubozu]
      bar[:bearish_close] = true if (bar[:close] - bar[:low])  <= rel and not bar[:marubozu]

      # the distribution of main volume is shown in 5 segments, like [0|0|0|4|5] shows that most volume concentrated at the bottom, [0|0|3|0|0] is heavily centered
      # TODO

    end 
    candles
  end

  def comparebars(prev, curr)
    bullishscore  = 0
    bearishscore  = 0
    bullishscore += 1 if prev[:high]  <= curr[:high]
    bullishscore += 1 if prev[:low]   <= curr[:low]
    bullishscore += 1 if prev[:close] <= curr[:close]
    bearishscore += 1 if prev[:close] >= curr[:close]
    bearishscore += 1 if prev[:low]   >= curr[:low]
    bearishscore += 1 if prev[:high]  >= curr[:high]
    r = {}
    r[:bullish] = true if bullishscore >= 2
    r[:bearish] = true if bearishscore >= 2
    return r
  end


  def patterns(candles, debug = false)
    candles.each_with_index do |bar, i|
      if i.zero?
        bar[:slope] = 0
        next
      end
      pprev= candles[i-2]
      prev = candles[i-1]
      succ = candles[i+1]

      bar[:tr]       = [ bar[:high], prev[:close] ].max - [bar[:low], prev[:close]].min
      bar[:ranges]   = prev[:ranges].nil? ? [ bar[:tr] ] : prev[:ranges] + [ bar[:tr] ] 
      bar[:ranges].shift while bar[:ranges].size > 5
      bar[:atr]      = (bar[:ranges].reduce(:+) / bar[:ranges].size.to_f).round(8) if bar[:ranges].size > 0

      bar[:vranges]  = prev[:vranges].nil? ? [ bar[:volume] ] : prev[:vranges] + [ bar[:volume] ] 
      bar[:vranges].shift while bar[:vranges].size > 5
      bar[:vavg]     = (bar[:vranges].reduce(:+) / bar[:vranges].size.to_f).round  if bar[:vranges].compact.size > 0



      # VOLUME
      if bar[:volume] > bar[:vavg] * 1.3
        bar[:BREAKN_volume] = true 
      elsif bar[:volume] >= bar[:vavg] * 1.1
        bar[:RISING_volume] = true 
      elsif bar[:volume] <  bar[:vavg]   * 0.7
        bar[:FAINTN_volume] = true
      elsif bar[:volume] <= bar[:vavg]  * 0.9 
        bar[:FALLIN_volume] = true
      else
        bar[:STABLE_volume] = true
      end

      # GAPS 
      bar[:bodygap] = true if bar[:lower] > prev[:upper] or bar[:upper] < prev[:lower] 
      bar[:gap]     = true if bar[:low] > prev[:high] or bar[:high] < prev[:low]


      bar[:slope] = slopescore(pprev, prev, bar, debug)

      # UPPER_PIVOTs define by having higher highs and higher lows than their neighor
      bar[:UPPER_ISOPIVOT] = true if succ and prev[:high]  < bar[:high] and prev[:low] <= bar[:low] and succ[:high] <  bar[:high] and succ[:low] <= bar[:low] and bar[:lower] >= [prev[:upper], succ[:upper]].max
      bar[:LOWER_ISOPIVOT] = true if succ and prev[:high] >= bar[:high] and prev[:low] >  bar[:low] and succ[:high] >= bar[:high] and succ[:low] >  bar[:low] and bar[:upper] <= [prev[:lower], succ[:lower]].min
      bar[:UPPER_PIVOT] = true if succ and prev[:high]  < bar[:high] and prev[:low] <= bar[:low] and succ[:high] <  bar[:high] and succ[:low] <= bar[:low] and not bar[:UPPER_ISOPIVOT]
      bar[:LOWER_PIVOT] = true if succ and prev[:high] >= bar[:high] and prev[:low] >  bar[:low] and succ[:high] >= bar[:high] and succ[:low] >  bar[:low] and not bar[:LOWER_ISOPIVOT]

      # stopping volume is defined as high volume candle during downtrend then closes above mid candle (i.e. lower_wick > body_size)
      bar[:stopping_volume] = true if bar[:BREAKN_volume] and prev[:slope] < -5 and bar[:lower_wick] >= bar[:body_size]
      bar[:stopping_volume] = true if bar[:BREAKN_volume] and prev[:slope] >  5 and bar[:upper_wick] >= bar[:body_size]
      bar[:volume_lower_wick] = true if bar[:vhigh] and (bar[:vol_i].nil? or bar[:vol_i] >= 2) and bar[:vhigh] <= bar[:lower] and not bar[:FAINTN_volume] and not bar[:FALLIN_volume]
      bar[:volume_upper_wick] = true if bar[:vlow]  and (bar[:vol_i].nil? or bar[:vol_i] >= 2) and bar[:vlow]  >= bar[:upper] and not bar[:FAINTN_volume] and not bar[:FALLIN_volume]


      ###################################
      # SINGLE CANDLE PATTERNS 
      ################################### 

      # a hammer is a bar, whose open or close is at the high and whose body is lte 1/3 of the size, found on falling slope, preferrably gapping away
      bar[:HAMMER]          = true if bar[:upper_wick] <=  bar[:rel] and bar[:body_size] <= bar[:bar_size] / 3 and bar[ :slope] <= -6
      # same shape, but found at a raising slope without the need to gap away
      bar[:HANGING_MAN]     = true if bar[:upper_wick] <=  bar[:rel] and bar[:body_size] <= bar[:bar_size] / 3 and prev[:slope] >=  6

      # a shooting star is the inverse of the hammer, while the inverted hammer is the inverse of the hanging man
      bar[:SHOOTING_STAR]   = true if bar[:lower_wick] <= bar[:rel] and bar[:body_size] <= bar[:bar_size] / 2.5 and bar[ :slope] >= 6      
      bar[:INVERTED_HAMMER] = true if bar[:lower_wick] <= bar[:rel] and bar[:body_size] <= bar[:bar_size] / 3   and prev[:slope] <= -6

      # a star is simply gapping away the preceding slope
      bar[:STAR]      = true if ((bar[:lower] >= prev[:upper] and bar[:slope] >= 6) or (bar[:upper] <= prev[:lower] and bar[:slope] <= -6)) and not bar[:doji]
      bar[:DOJI_STAR] = true if ((bar[:lower] >= prev[:upper] and bar[:slope] >= 6) or (bar[:upper] <= prev[:lower] and bar[:slope] <= -6)) and     bar[:doji]

      # a belthold is has a gap in the open, but reverses strong
      bar[:BULLISH_BELTHOLD] = true if bar[:lower_wick] <= bar[:rel] and bar[:body_size] >= bar[:bar_size] / 2 and 
                                       prev[:slope] <= -4 and bar[:lower] <= prev[:low ] and bar[:bullish] and not prev[:bullish] and bar[:bar_size] >= prev[:bar_size]
      bar[:BEARISH_BELTHOLD] = true if bar[:upper_wick] <= bar[:rel] and bar[:body_size] >= bar[:bar_size] / 2 and 
                                       prev[:slope] >= -4 and bar[:upper] <= prev[:high] and bar[:bearish] and not prev[:bearish] and bar[:bar_size] >= prev[:bar_size]


      ###################################
      # DUAL CANDLE PATTERNS
      ###################################


      # ENGULFINGS
      bar[:BULLISH_ENGULFING] = true if bar[:bullish] and prev[:bearish] and bar[:lower] <= prev[:lower] and bar[:upper] >  prev[:upper] and prev[:slope] <= -6
      bar[:BEARISH_ENGULFING] = true if bar[:bearish] and prev[:bullish] and bar[:lower] <  prev[:lower] and bar[:upper] >= prev[:upper] and prev[:slope] >=  6


      # DARK-CLOUD-COVER / PIERCING-LINE (on-neck / in-neck / thrusting / piercing / PDF pg 63)
      bar[:DARK_CLOUD_COVER]  = true if bar[:slope] > 5  and prev[:bullish] and bar[:open] > prev[:high] and bar[:close] < prev[:upper] - prev[:body_size] * 0.5  and 
                                                         not bar[:BEARISH_ENGULFING]
      bar[:PIERCING_LINE]     = true if bar[:slope] < -5 and prev[:bearish] and bar[:open] < prev[:low ] and bar[:close] > prev[:lower] + prev[:body_size] * 0.5  and 
                                                         not bar[:BULLISH_ENGULFING]
      bar[:SMALL_CLOUD_COVER] = true if bar[:slope] > 5  and prev[:bullish] and bar[:open] > prev[:high] and bar[:close] < prev[:upper] - prev[:body_size] * 0.25 and 
                                                         not bar[:BEARISH_ENGULFING] and not bar[:DARK_CLOUD_COVER]
      bar[:THRUSTING_LINE]    = true if bar[:slope] < -5 and prev[:bearish] and bar[:open] < prev[:low ] and bar[:close] > prev[:lower] + prev[:body_size] * 0.25 and 
                                                         not bar[:BULLISH_ENGULFING] and not bar[:PIERCING_LINE]


      # COUNTER ATTACKS are like piercings / cloud covers, but insist on a large reverse while only reaching the preceding close
      bar[:BULLISH_COUNTERATTACK] = true if bar[:slope] < 6 and prev[:bearish] and bar[:bar_size] > bar[:atr] * 0.66 and (bar[:close] - prev[:close]).abs < 2 * bar[:rel] and 
                                            bar[:body_size] >= bar[:bar_size] * 0.5 and bar[:bullish]
      bar[:BEARISH_COUNTERATTACK] = true if bar[:slope] > 6 and prev[:bullish] and bar[:bar_size] > bar[:atr] * 0.66 and (bar[:close] - prev[:close]).abs < 2 * bar[:rel] and
                                            bar[:body_size] >= bar[:bar_size] * 0.5 and bar[:bearish]


      # HARAMIs are an unusual long body embedding the following small body
      bar[:HARAMI]       = true if bar[:body_size] < prev[:body_size] / 2.5 and prev[:bar_size] >= bar[:atr] and 
                                  prev[:upper] > bar[:upper] and prev[:lower] < bar[:lower] and not bar[:doji]
      bar[:HARAMI_CROSS] = true if bar[:body_size] < prev[:body_size] / 2.5 and prev[:bar_size] >= bar[:atr] and
                                  prev[:upper] > bar[:upper] and prev[:lower] < bar[:lower] and     bar[:doji]
      if bar[:HARAMI] or bar[:HARAMI_CROSS]
        puts [ :date, :open, :high, :low, :close, :upper, :lower ].map{|x| prev[x]}.join("\t") if debug
        puts [ :date, :open, :high, :low, :close, :upper, :lower ].map{|x| bar[ x]}.join("\t") if debug
        puts  "" if debug
      end

      # TODO TWEEZER_TOP and TWEEZER_BOTTOM
      # actually being a double top / bottom, this dual candle pattern has to be unfolded. It is valid on daily or weekly charts, 
      # and valid if 
      #     1 it has an according 


      ###################################
      # TRIPLE CANDLE PATTERNS
      ###################################

      # morning star, morning doji star
      next unless prev and pprev
      bar[:MORNING_STAR]      = true if prev[:STAR]      and bar[:bullish] and bar[:close] >= pprev[:lower] and prev[:slope] < -6
      bar[:MORNING_DOJI_STAR] = true if prev[:DOJI_STAR] and bar[:bullish] and bar[:close] >= pprev[:lower] and prev[:slope] < -6 
      bar[:EVENING_STAR]      = true if prev[:STAR]      and bar[:bearish] and bar[:close] <= pprev[:upper] and prev[:slope] >  6
      bar[:EVENING_DOJI_STAR] = true if prev[:DOJI_STAR] and bar[:bearish] and bar[:close] <= pprev[:upper] and prev[:slope] >  6

      # the abandoned baby escalates above stars by gapping the inner star candle to both framing it
      bar[:ABANDONED_BABY]    = true if (bar[:MORNING_STAR] or bar[:MORNING_DOJI_STAR]) and prev[:high] <= [ pprev[:low ], bar[:low ] ].min
      bar[:ABANDONED_BABY]    = true if (bar[:EVENING_STAR] or bar[:EVENING_DOJI_STAR]) and prev[:low ] >= [ pprev[:high], bar[:high] ].max

      # UPSIDEGAP_TWO_CROWS
      bar[:UPSIDEGAP_TWO_CROWS] = true if (prev[:STAR] or prev[:DOJI_STAR]) and prev[:slope] > 4 and bar[:bearish] and prev[:bearish] and bar[:close] > pprev[:close]
      bar[:DOWNGAP_TWO_RIVERS]  = true if (prev[:STAR] or prev[:DOJI_STAR]) and prev[:slope] < 4 and bar[:bullish] and prev[:bullish] and bar[:close] < pprev[:close]

      # THREE BLACK CROWS / THREE WHITE SOLDIERS
      bar[:THREE_BLACK_CROWS]   = true if [ bar, prev, pprev ].map{|x| x[:bearish] and x[:bar_size] > 0.5 * bar[:atr] }.reduce(:&) and 
                                          pprev[:close] - prev[ :close] > bar[:atr] * 0.2 and 
                                          prev[ :close] - bar[  :close] > bar[:atr] * 0.2
      bar[:THREE_WHITE_SOLDIERS] = true if [ bar, prev, pprev ].map{|x| x[:bullish] and x[:bar_size] > 0.5 * bar[:atr] }.reduce(:&) and
                                          prev[:close]  - pprev[:close] > bar[:atr] * 0.2 and 
                                          bar[ :close]  - prev[ :close] > bar[:atr] * 0.2
    end
  end


  # SLOPE SCORE
  def slopescore(pprev, prev, bar, debug = false)
    # the slope between to bars is considered bullish, if 2 of three points match
    #     - higher high
    #     - higher close
    #     - higher low
    # the opposite counts for bearish
    # 
    # this comparison is done between the current bar and previous bar
    #     - if it confirms the score of the previous bar, the new slope score is prev + curr
    #     - otherwise the is compared to score of the pprevious bar
    #         - if it confirms there, the new slope score is pprev + curr
    #         - otherwise the trend is destroyed and tne new score is solely curr

    if bar[:bullish]
      curr  = 1
      curr += 1   if bar[:bullish_close]
    elsif bar[:bearish]
      curr  = -1 
      curr -=  1  if bar[:bearish_close]
    else
      curr  = 0
    end
    puts "curr set to #{curr} @ #{bar[:date]}".yellow if debug
    if prev.nil?
      puts "no prev found, score == curr: #{curr}" if debug
      score = curr
    else
      comp = comparebars(prev, bar)

      puts prev.select{|k,v| [:high,:low,:close,:score].include?(k)} if debug
      puts bar if debug
      puts "COMPARISON 1: #{comp}" if debug

      if prev[:slope] >= 0 and comp[:bullish]     # bullish slope confirmed
        score  = prev[:slope]
        score += curr if curr > 0
        [ :gap, :bodygap ] .each {|x| score += 0.5  if bar[x] }
        score += 1 if bar[:RISING_volume]
        score += 2 if bar[:BREAKN_volume]
        puts "found bullish slope confirmed, new score #{score}" if debug
      elsif prev[:slope] <= 0 and comp[:bearish]  # bearish slope confirmed
        score  = prev[:slope] 
        score += curr if curr < 0
        [ :gap, :bodygap ] .each {|x| score -= 0.5  if bar[x] }
        score -= 1 if bar[:RISING_volume]
        score -= 2 if bar[:BREAKN_volume]
        puts "found bearish slope confirmed, new score #{score} (including #{curr} and #{bar[:bodygap]} and #{bar[:gap]}" if debug
      else #if prev[:slope] > 0                     # slopes failed
        puts "confirmation failed: " if debug
        if pprev.nil? 
          score = curr
        else
          comp2 = comparebars(pprev, bar)
          puts "\t\tCOMPARISON 2: #{comp2}" if debug
          if pprev[:slope] >= 0 and comp2[:bullish]     # bullish slope confirmed on pprev
            score  = pprev[:slope]
            score += curr if curr > 0
            [ :gap, :bodygap ] .each {|x| score += 0.5  if bar[x] }
            puts "\t\tfound bulliish slope confirmed, new score #{score}" if debug
            score += 1 if bar[:RISING_volume]
            score += 2 if bar[:BREAKN_volume]
          elsif pprev[:slope] <= 0 and comp2[:bearish]  # bearish slope confirmed
            score  = pprev[:slope]
            score += curr if curr < 0
            [ :gap, :bodygap ] .each {|x| score -= 0.5  if bar[x] }
            score -= 1 if bar[:RISING_volume]
            score -= 2 if bar[:BREAKN_volume]
            puts "\t\tfound bearish slope confirmed, new score #{score}" if debug
          else                                          #slope confirmation finally failed
            comp3 = comparebars(pprev, prev)
            if prev[:slope] > 0 # was bullish, turning bearish now
              score  = curr                     
              score -= 1 if comp3[:bearish]
              score -= 1 if comp[:bearish]
              score -= 1 if prev[:bearish]
              score -= 1 if prev[:RISING_volume] and comp3[:bearish]
              score -= 2 if prev[:BREAKN_volume] and comp3[:bearish]
              score -= 1 if bar[:RISING_volume] and comp[:bearish]
              score -= 2 if bar[:BREAKN_volume] and comp[:bearish]
              score -= 1 if bar[:RISING_volume] and comp[:bearish]
              score -= 2 if bar[:BREAKN_volume] and comp[:bearish]
              [ :gap, :bodygap ] .each {|x| score += 0.5  if bar[x] } 
              puts "\t\tfinally gave up, turning bearish now, new score #{score}" if debug
            elsif prev[:slope] < 0
              score = curr
              score += 1 if comp3[:bullish]
              score += 1 if comp[:bullish]
              score += 1 if prev[:bullish]
              score += 1 if prev[:RISING_volume] and comp3[:bullish]
              score += 2 if prev[:BREAKN_volume] and comp3[:bullish]
              score += 1 if bar[:RISING_volume] and comp[:bullish]
              score += 2 if bar[:BREAKN_volume] and comp[:bullish]
              score += 1 if bar[:RISING_volume] and comp[:bullish]
              score += 2 if bar[:BREAKN_volume] and comp[:bullish]
              [ :gap, :bodygap ] .each {|x| score -= 0.5  if bar[x] } if curr < 0
              puts "\t\tfinally gave up, turning bullish now, new score #{score}" if debug
            else
              score = 0
            end
          end
        end
      end
    end
    puts "" if debug
    score
  end

end

CR = Candlestick_Recognition
