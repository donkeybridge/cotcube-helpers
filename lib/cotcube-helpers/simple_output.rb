# frozen_string_literal: true

module Cotcube
  module Helpers
    # SimpleOutput is a very basic outputhandler, which is actually only there to mock output handling until
    #   a more sophisticated solution is available (e.g. OutPutHandler gem is reworked and tested )
    class SimpleOutput
      # Aliasing puts and print, as they are included / inherited (?) from IO
      alias_method :superputs,  :puts # rubocop:disable Style/Alias
      # Aliasing puts and print, as they are included / inherited (?) from IO
      alias_method :superprint, :print # rubocop:disable Style/Alias

      # ...
      def puts(msg)
        superputs msg
      end

      # ...
      def print(msg)
        superprint msg
      end

      # The source expects methods with exclamation mark (for unbuffered output) -- although it makes no sense
      #   here, we need to provide the syntax for later.
      alias puts!  puts
      alias print! print
    end
  end
end
