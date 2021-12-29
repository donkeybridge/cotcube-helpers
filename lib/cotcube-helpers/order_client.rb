#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bunny'
require 'json'

module Cotcube
  module Helpers
    class OrderClient
      SECRETS_DEFAULT = {
        'orderproxy_mq_proto'    => 'http',
        'orderproxy_mq_user'     => 'guest',
        'orderproxy_mq_password' => 'guest',
        'orderproxy_mq_host'     => 'localhost',
        'orderproxy_mq_port'     => '15672',
        'orderproxy_mq_vhost'    => '%2F'
      }.freeze

      SECRETS = SECRETS_DEFAULT.merge(
        lambda {
          begin
            YAML.safe_load(File.read(Cotcube::Helpers.init[:secrets_file]))
          rescue StandardError
            {}
          end
        }.call
      )

      def initialize
        @connection = Bunny.new(user:     SECRETS['orderproxy_mq_user'],
                                password: SECRETS['orderproxy_mq_password'],
                                vhost:    SECRETS['orderproxy_mq_vhost'])
        @connection.start

        @commands  = connection.create_channel
        @exchange  = commands.direct('orderproxy_commands')
        @requests  = {}
        @persistent = { depth: {}, realtimebars: {}, ticks: {} }
        @debug     = false
        setup_reply_queue
      end

      # command acts a synchronizer: it sends the command and waits for the response
      #     otherwise times out --- the counterpart here is the subscription within 
      #     setup_reply_queue
      #
      def command(command, timeout: 10)
        command = { command: command.to_s } unless command.is_a? Hash
        command[:timestamp] ||= (Time.now.to_f * 1000).to_i
        request_id = Digest::SHA256.hexdigest(command.to_json)[..6]
        requests[request_id] = {
          request: command,
          id: request_id,
          lock: Mutex.new,
          condition: ConditionVariable.new
        }

        exchange.publish(command.to_json,
                         routing_key: 'orderproxy_commands',
                         correlation_id: request_id,
                         reply_to: reply_queue.name)

        # wait for the signal to continue the execution
        #
        requests[request_id][:lock].synchronize do
          requests[request_id][:condition].wait(requests[request_id][:lock], timeout)
        end

        # if we reached timeout, we will return nil, just for explicity
        response = requests[request_id][:response].dup
        requests.delete(request_id)
        response
      end

      alias_method :send_command, :command

      def stop
        commands.close
        connection.close
      end

      def get_contracts(symbol:)
        send_command({ command: :get_contracts, symbol: symbol })
      end

      attr_accessor :response
      attr_reader   :lock, :condition

      private

      attr_reader :call_id, :connection, :requests, :persistent,
                  :commands, :server_queue_name, :reply_queue, :exchange

      def setup_reply_queue
        @reply_queue = commands.queue('', exclusive: true, auto_delete: true)
        @reply_queue.bind(commands.exchange('orderproxy_replies'), routing_key: @reply_queue.name)

        reply_queue.subscribe do |delivery_info, properties, payload|
          __id__ = properties[:correlation_id]

          if __id__.nil?
            puts "Received without __id__: #{delivery_info.map       { |k, v| "#{k}\t#{v}" }.join("\n")
                                      }\n\n#{properties.map          { |k, v| "#{k}\t#{v}" }.join("\n")
                                      }\n\n#{JSON.parse(payload).map { |k, v| "#{k}\t#{v}" }.join("\n")}" if @debug

          elsif requests[__id__].nil?
            puts "Received non-matching response, maybe previously timed out: \n\n#{delivery_info}\n\n#{properties}\n\n#{payload}\n."[..620].scan(/.{1,120}/).join(' '*30 + "\n") if @debug
          else
            # save the payload and send the signal to continue the execution of #command
            # need to rescue the rare case, where lock and condition are destroyed right in parallel by timeout
            begin 
              puts "Received result for #{__id__}" if @debug
              requests[__id__][:response] = payload
              requests[__id__][:lock].synchronize { requests[__id__][:condition].signal }
            rescue nil
            end
          end
        end
      end
    end
  end
end

__END__
begin 
  client = OrderClient.new
  reply = client.send_command( { command: 'ping' } ) 
  puts reply.nil? ? 'nil' : JSON.parse(reply)
ensure
  client.stop
end
