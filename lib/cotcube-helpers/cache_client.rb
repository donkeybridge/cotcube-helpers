require 'httparty'
require 'json'

module Cotcube
  module Helpers
    class CacheClient

      def initialize(query='keys', timezone: Cotcube::Helpers::CHICAGO, debug: false, deflate: false, update: false)
        raise ArgumentError, "Query must not be empty." if [ nil, '' ].include? query
        raise ArgumentError, "Query '#{query}' is garbage." if query.split('/').size > 2 or not query.match? /\A[a-zA-Z0-9?=\/]+\Z/
        @update = update ? '?update=true' : ''
        @request_headers = {} 
        @request_headers['Accept-Encoding'] = 'deflate' if deflate
        @query = query
        @result = JSON.parse(HTTParty.get("http://100.100.0.14:8081/#{query}#{@update}").body, headers: @request_headers, symbolize_names: true) rescue { error: 1, msg: "Could not parse response for query '#{query}'." }
        retry_once if has_errors?
      end

      def retry_once
        sleep 2
        raw = HTTParty.get("http://100.100.0.14:8081/#{query}#{update}")
        @result = JSON.parse(raw.body, symbolize_names: true) rescue { error: 1, msg: "Could not parse response for query '#{query}'." }
        if has_errors?
          puts "ERROR in parsing response: #{raw[..300]}"
        end
      end

      def has_errors?
        result[:error].nil? or result[:error] > 0
      end

      def warnings
        result[:warnings]
      end

      def payload
        has_errors? ? false : @result[:payload]
      end

      def entity
        query.split('/').first
      end

      def asset
        entity, asset = query.split('/')
        asset
      end

      attr_reader :query, :result, :update
    end
  end
end
