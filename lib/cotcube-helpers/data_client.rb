#!/usr/bin/env ruby
require 'bunny'
require 'json'

module Cotcube
  module Helpers
    class DataClient

      def initialize
        @connection = Bunny.new(automatically_recover: true)
        @connection.start

        @channel  = connection.create_channel
        @exchange = channel.direct('dataproxy_commands', auto_delete: true)
        @requests = {} 
        @persistent = { depth: {}, realtimebars: {}, ticks: {} }

        setup_reply_queue
      end

      def help
        puts "The following commands are available:\n\n"\
          "\tcontracts  = client.get_contracts(symbol:)\n"\
          "\tbars       = client.get_historical(contract:, duration:, interval:, before: nil)"\
          "\trequest_id = client.start_realtimebars(contract: )\n"\
          "\t             client.stop_realtimebars(request_id: )\n"\
          "\trequest_id = client.start_ticks(contract: )\n"\
          "\t             client.stop_ticks(request_id: )\n"
      end

      def send_command(command, timeout: 5)
        command = { command: command.to_s } unless command.is_a? Hash
        command[:timestamp] ||= (Time.now.to_f * 1000).to_i
        request_id = Digest::SHA256.hexdigest(command.to_json)[..6]
        requests[request_id] = { request: command, id: request_id }

        exchange.publish(command.to_json,
                         routing_key: 'dataproxy_commands',
                         correlation_id: request_id,
                         reply_to: reply_queue.name)

        # wait for the signal to continue the execution
        lock.synchronize { 
          condition.wait(lock, timeout) 
        } 

        response
      end

      def stop
        channel.close
        connection.close
      end


      def get_contracts(symbol: )
        send_command( { command: :get_contracts, symbol: symbol } )
      end

      def get_historical(contract:, interval:, duration: nil, before: nil, rth_only: false, based_on: :trades)
        # rth.true? means data outside of rth is skipped
        rth_only = rth_only ? 1 : 0
        default_durations = {
          sec1:  '30_M',
          sec5:   '2_H',
          sec15:  '6_H',
          sec30: '12_H',
          min1:   '1_D',
          min2:   '2_D',
          min5:   '5_D',
          min15:  '1_W',
          min30:  '1_W',
          hour1:  '1_W',
          day1:   '1_Y'
        } 
        raise "Invalid interval '#{interval}', should be in '#{default_durations.keys}'." unless default_durations.keys.include? interval
        # TODO: Check for valid duration specification
        duration ||= default_durations[interval] 
        send_command( { 
          command: :historical,
          contract: contract,
          interval: interval,
          duration: duration,
          based_on: based_on.to_s.upcase,
          rth_only: rth_only,
          before: nil
        }, timeout: 20 )
      end

      def start_persistent(contract:, type: :realtimebars, &block)
        unless %i[ depth ticks realtimebars].include? type.to_sym
          puts "ERROR: Inappropriate type in stop_realtimebars with #{type}"
          return false
        end

        ib_contract = Cotcube::Helpers.get_ib_contract(contract)
        exchange = channel.fanout( "dataproxy_#{type.to_s}_#{contract}", auto_delete: true)
        queue  = channel.queue('', exclusive: true, auto_delete: true)
        queue.bind(exchange)
        block ||= ->(bar){ puts "#{bar}" }
        queue.subscribe do  |_delivery_info, properties, payload|
          block.call(JSON.parse(payload, symbolize_names: true))
        end
        command = { command: type, contract: contract, con_id: ib_contract[:con_id], delivery: queue.name, exchange: exchange.name }
        persistent[type][queue.name] = command
        persistent[type][queue.name][:queue] = queue
        send_command(command)
      end

      def stop_persistent(contract:, type: :realtimebars )
        unless %i[ depth ticks realtimebars].include? type.to_sym
          puts "ERROR: Inappropriate type in stop_realtimebars with #{type}"
          return false
        end
        ib_contract = Cotcube::Helpers.get_ib_contract(contract)
        command = { command: "stop_#{type}", contract: contract, con_id: ib_contract[:con_id] }
        send_command(command)
      end

      private
      attr_accessor :call_id, :response, :lock, :condition, :connection,
        :channel, :server_queue_name, :reply_queue, :exchange,
        :requests, :persistent


      def setup_reply_queue
        @lock = Mutex.new
        @condition = ConditionVariable.new
        that = self
        @reply_queue = channel.queue('', exclusive: true, auto_delete: true)
        @reply_queue.bind(channel.exchange('dataproxy_replies', auto_delete: true), routing_key: @reply_queue.name)

        reply_queue.subscribe do |_delivery_info, properties, payload|
          if requests[that.call_id].nil?
            that.response = payload

            # sends the signal to continue the execution of #call
            requests.delete(that.call_id)
            that.lock.synchronize { that.condition.signal }
          else
            puts "Received non-matching response: \n\n#{_delivery_info}\n\n#{properties}\n\n#{payload}\n."
          end
        end
      end

    end
  end
end

__END__
begin 
  client = DataClient.new
  reply = client.send_command( { command: 'ping' } ) #{ command: :hist, contract: 'A6Z21', con_id: 259130514, interval: :min15 } )
  puts reply.nil? ? 'nil' : JSON.parse(reply)
  reply = client.get_historical( contract: 'A6Z21',  con_id: 259130514, interval: :min15 , rth_only: false)
  JSON.parse(reply, symbolize_names: true)[:result].map{|z| 
    z[:datetime] = Cotcube::Helpers::CHICAGO.parse(z[:time]).strftime('%Y-%m-%d %H:%M:%S')
    z.delete(:created_at)
    z.delete(:time)
    p z.slice(*%i[datetime open high low close volume]).values

  } 
ensure
  client.stop
  e,nd
