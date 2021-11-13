#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bunny'
require 'json'

module Cotcube
  module Helpers
    class DataClient
      SECRETS_DEFAULT = {
        'dataproxy_mq_proto' => 'http',
        'dataproxy_mq_user' => 'guest',
        'dataproxy_mq_password' => 'guest',
        'dataproxy_mq_host' => 'localhost',
        'dataproxy_mq_port' => '15672',
        'dataproxy_mq_vhost' => '%2F'
      }.freeze

      SECRETS = SECRETS_DEFAULT.merge(
        lambda {
          begin
            YAML.safe_load(File.read("#{__FILE__.split('/')[..-4].join('/')}/secrets.yml"))
          rescue StandardError
            {}
          end
        }.call
      )

      def initialize
        @connection = Bunny.new(user: SECRETS['dataproxy_mq_user'],
                                password: SECRETS['dataproxy_mq_password'],
                                vhost: SECRETS['dataproxy_mq_vhost'])
        @connection.start

        @commands  = connection.create_channel
        @exchange  = commands.direct('dataproxy_commands', auto_delete: true)
        @requests  = {}
        @persistent = { depth: {}, realtimebars: {}, ticks: {} }

        setup_reply_queue
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
        lock.synchronize do
          condition.wait(lock, timeout)
        end

        response
      end

      def stop
        %i[depth ticks realtimebars].each do |type|
          persistent[type].each do |local_key, obj|
            puts "Cancelling #{local_key}"
            obj[:subscription].cancel
          end
        end
        commands.close
        connection.close
      end

      def get_contracts(symbol:)
        send_command({ command: :get_contracts, symbol: symbol })
      end

      def get_historical(contract:, interval:, duration: nil, before: nil, rth_only: false, based_on: :trades)
        # rth.true? means data outside of rth is skipped
        rth_only = rth_only ? 1 : 0
        default_durations = { sec1: '30_M', sec5:   '2_H', sec15:  '6_H', sec30: '12_H',
                              min1: '1_D', min2:   '2_D', min5:   '5_D', min15:  '1_W',
                              min30: '1_W', hour1:  '1_W', day1:   '1_Y' }

        unless default_durations.keys.include? interval
          raise "Invalid interval '#{interval}', should be in '#{default_durations.keys}'."
        end

        # TODO: Check for valid duration specification
        puts 'WARNING in get_historical: param :before ignored' unless before.nil?
        duration ||= default_durations[interval]
        send_command({
                       command: :historical,
                       contract: contract,
                       interval: interval,
                       duration: duration,
                       based_on: based_on.to_s.upcase,
                       rth_only: rth_only,
                       before: nil
                     }, timeout: 20)
      end

      def start_persistent(contract:, type: :realtimebars, local_id: 0, &block)
        unless %i[depth ticks realtimebars].include? type.to_sym
          puts "ERROR: Inappropriate type in stop_realtimebars with #{type}"
          return false
        end

        local_key = "#{contract}_#{local_id}"

        channel = connection.create_channel
        exchange  = channel.fanout("dataproxy_#{type}_#{contract}")
        queue     = channel.queue('', exclusive: true, auto_delete: true)
        queue.bind(exchange)

        ib_contract = Cotcube::Helpers.get_ib_contract(contract)

        command = { command: type, contract: contract, con_id: ib_contract[:con_id],
                    delivery: queue.name, exchange: exchange.name }

        block      ||= ->(bar) { puts bar.to_s }

        subscription = queue.subscribe do |_delivery_info, _properties, payload|
          block.call(JSON.parse(payload, symbolize_names: true))
        end
        persistent[type][local_key] = command.dup
        persistent[type][local_key][:queue] = queue
        persistent[type][local_key][:subscription] = subscription
        persistent[type][local_key][:channel] = channel
        send_command(command)
      end

      def stop_persistent(contract:, local_id: 0, type: :realtimebars)
        unless %i[depth ticks realtimebars].include? type.to_sym
          puts "ERROR: Inappropriate type in stop_realtimebars with #{type}"
          return false
        end
        local_key = "#{contract}_#{local_id}"
        p persistent[type][local_key][:subscription].cancel
        p persistent[type][local_key][:channel].close
        persistent[type].delete(local_key)
      end

      attr_accessor :response
      attr_reader   :lock, :condition

      private

      attr_reader :call_id, :connection, :requests, :persistent,
                  :commands, :server_queue_name, :reply_queue, :exchange

      def setup_reply_queue
        @lock = Mutex.new
        @condition = ConditionVariable.new
        that = self
        @reply_queue = commands.queue('', exclusive: true, auto_delete: true)
        @reply_queue.bind(commands.exchange('dataproxy_replies', auto_delete: true), routing_key: @reply_queue.name)

        reply_queue.subscribe do |delivery_info, properties, payload|
          __id__ = properties[:correlation_id]

          if __id__.nil?
            puts "Received without __id__: #{delivery_info.map       { |k, v| "#{k}\t#{v}" }.join("\n")
                                      }\n\n#{properties.map          { |k, v| "#{k}\t#{v}" }.join("\n")
                                      }\n\n#{JSON.parse(payload).map { |k, v| "#{k}\t#{v}" }.join("\n")}"

          elsif requests[__id__].nil?
            puts "Received non-matching response: \n\n#{delivery_info}\n\n#{properties}\n\n#{payload}\n."
          else
            that.response = payload

            # sends the signal to continue the execution of #call
            requests.delete(__id__)
            that.lock.synchronize { that.condition.signal }
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
