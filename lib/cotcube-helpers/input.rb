module Cotcube
  module Helpers
    def keystroke(quit: false)
      begin
        # save previous state of stty
        old_state = `stty -g`
        # disable echoing and enable raw (not having to press enter)
        system "stty raw -echo"
        c = STDIN.getc.chr
        # gather next two characters of special keys
        if(c=="\e")
          extra_thread = Thread.new{
            c = c + STDIN.getc.chr
            c = c + STDIN.getc.chr
          }
          # wait just long enough for special keys to get swallowed
          extra_thread.join(0.00001)
          # kill thread so not-so-long special keys don't wait on getc
          extra_thread.kill
        end
      rescue => ex
        puts "#{ex.class}: #{ex.message}"
        puts ex.backtrace
      ensure
        # restore previous state of stty
        system "stty #{old_state}"
      end
      c.each_byte do |x| 
        case x
        when 3
          puts "Strg-C captured, exiting..."
          quit ? exit : (return true)
        when 13
          return "_return_"
        when 27
          puts "ESCAPE gathered"
          return "_esc_"
        else
          return c
        end
      end
    end
  end
end
