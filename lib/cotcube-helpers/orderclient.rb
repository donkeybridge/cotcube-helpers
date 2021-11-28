# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module Cotcube
  module Helpers
    # A proxyclient is a wrapper that allows communication with cotcube-orderproxy and cotcube-dataproxy. It fulfills
    # registration and provides the opportunity to implement the logic to respond do events.
    # (orderproxy and dataproxy are separate gems creating a layer between tws/ib-ruby and cotcube-based
    #  applications)
    #
    #  NOTE: Whats here is a provisionally version
    #
    class DataClient # rubocop:disable Metrics/ClassLength
      attr_reader :power, :ticksize, :multiplier, :average, :account

      # The constructor takes a lot of arguments:
      def initialize(
        debug: false,
        contract: ,
        serverport: 24001,
        serveraddr: '127.0.0.1',
        client:,
        bars: true,
        ticks: false,
        bar_size: 5,
        spawn_timeout: 15
      )
        require 'json'   unless Hash.new.respond_to? :to_json
        require 'socket' unless defined? TCPSocket

        puts 'PROXYCLIENT: Debug enabled' if @debug

        @contract = contract.upcase
        %w[debug serverport serveraddr client bars ticks bar_size].each {|var| eval("@#{var} = #{var}")}

        @position     = 0
        @account      = 0
        @average      = 0

        exit_on_startup(':client must be in range 24001..24999') if @client.nil? || (@client / 1000 != 24) || (@client == 24_000)

        res = send_command({ command: 'register', contract: @contract, date: @date,
                             ticks: @ticks, bars: @bars, bar_size: @bar_size })

        # spawn_server has to be called separately after initialization. 
        print "Waiting #{spawn_timeout} seconds on server_thread to spawn..."
        Thread.new do 
          begin 
            Timeout.timeout(spawn_timeout) { sleep(0.1) while @server_thread.nil? }
          rescue Timeout::Error
            puts 'Could not get server_thread, has :spawn_server been called?' 
            shutdown
          end
        end

        unless res['error'].zero?
          exit_on_startup("Unable to register on orderproxy, exiting")
        end
      end

      def exit_on_startup(msg = '')
        puts "Cannot startup client, exiting during startup: '#{msg}'"
        shutdown
        defined?(::IRB) ? (raise) : (exit 1)
      end

      def send_command(req)
        req[:client_id] = @client
        res = nil
        puts "Connecting to #{@serveraddr}:#{@serverport} to send '#{req}'." if @debug

        TCPSocket.open(@serveraddr, @serverport) do |proxy|
          proxy.puts(req.to_json)
          raw = proxy.gets
          begin
            res = JSON.parse(raw)
          rescue StandardError
            puts 'Error while parsing response'
            return false
          end
          if @debug
            # rubocop:disable Style/FormatStringToken, Style/FormatString
            res.each do |k, v|
              case v
              when Array
                (v.size < 2) ? puts(format '%-15s', "#{k}:") : print(format '%-15s', "#{k}:")
                v.each_with_index { |x, i| i.zero? ? (puts x) : (puts "               #{x}") }
              else
                puts "#{format '%-15s', "#{k}:"}#{v}"
              end
            end
            # rubocop:enable Style/FormatStringToken, Style/FormatString
          end
          puts "ERROR on command: #{res['msg']}" unless res['error'].nil? or res['error'].zero?
        end
        puts res.to_s if @debug
        res
      end

      # #shutdown ends the @server_thread and --if :close is set-- closes the current position attached to the client
      def shutdown(close: true)
        return if @shutdown
        @shutdown = true

        if @position.abs.positive? && close
          send_command({ command: 'order', action: 'create', type: 'market',
                         side: (@position.positive? ? 'sell' : 'buy'), size: @position.abs })
        end
        sleep 3
        result = send_command({ command: 'unregister' })
        puts "FINAL ACCOUNT: #{@account}"
        result['executions']&.each do |x|
          x.delete('msg_type')
          puts x.to_s
        end
        @server_thread.exit if @server_thread.respond_to? :exit
      end

      def spawn_server(
        execution_proc: nil,
        orderstate_proc: nil, 
        tick_proc: nil,
        depth_proc: nil, 
        order_proc: nil, 
        bars_proc: nil
      )                                           # rubocop:disable Metrics/MethodLength

        %w[execution_proc orderstate_proc tick_proc depth_proc order_proc bars_proc].each {|var| eval("@#{var} = #{var}") }

        if @bars 
          @bars_proc ||= lambda {|msg| puts msg.inspect }
        end

        if @ticks
          @ticks_proc ||= lambda {|msg| puts msg.inspect }
        end

        if @shutdown
          puts "Cannot spawn server on proxyclient that has been already shut down."
          return
        end
        if @server_thread
          puts "Cannot spawn server more than once."
          return
        end

        @server_thread = Thread.new do                                      # rubocop:disable Metrics/BlockLength
          puts 'Spawning RECEIVER'
          server = TCPServer.open(@serveraddr, @client)
          loop do                                                           # rubocop:disable Metrics/BlockLength
            Thread.start(server.accept) do |client|                         # rubocop:disable Metrics/BlockLength
              while (response = client.gets)
                response = JSON.parse(response)

                case response['msg_type']

                when 'alert'
                  case response['code']
                  when 2104
                    puts 'ALERT: data farm connection resumed   __ignored__'.light_black
                  when 2108
                    puts 'ALERT: data farm connection suspended __ignored__'.light_black
                  when 2109
                    # Order Event Warning:Attribute 'Outside Regular Trading Hours' is ignored
                    # based on the order type and destination. PlaceOrder is now being processed.
                    puts 'ALERT: outside_rth __ignored__'.light_black
                  when 2100
                    puts 'ALERT: Account_info unsubscribed __ignored__'.light_black
                  when 202
                    puts 'ALERT: order cancelled'
                  else
                    puts '-------------ALERT------------------------------'
                    puts response.to_s
                    puts '------------------------------------------------'
                  end

                when 'tick'
                  @tick_proc&.call(response)

                when 'depth'
                  @depth_proc&.call(response)

                when 'realtimebar'
                  @bars_proc&.call(response)

                else
                  puts "ERROR:       #{response}"

                end
              end
            end
          rescue StandardError => e
            backtrace = e.backtrace.join("\r\n")
            puts "======= ERROR: '#{e.class}', MESSAGE: '#{e.message}'\n#{backtrace}"
          end
        end
        puts '@server_thread spawned'
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
