require 'httparty'
require 'json'

module Cotcube
  module Helpers
    def cached(query, timezone: Cotcube::Helpers::CHICAGO, debug: false, deflate: false)
      # TODO: set param to enable deflate on transmission via HTTPARRTY Header
      request_headers = {} 
      request_headers['Accept-Encoding' => 'deflate'] if deflate
      res = JSON.parse(HTTParty.get("http://100.100.0.14:8081/#{query}").parsed_response, symbolize_names: true) rescue { error: 1, msg: "Could not parse response for query '#{query}'." }
      unless res[:error] and res[:error].zero? 
        puts "ERROR: #{res}"
        return false
      end
      #res[:valid_until] = timezone.parse(res[:valid_until])
      #res[:modified]    = timezone.parse(res[:modified_at])
      if debug
        puts "Warnings: #{res[:warnings]}"
        puts "Modified: #{res[:modified]}"
        puts "Valid_un: #{res[:valid_until]}"
        puts "payload:  #{res[:payload].to_s.size}"
      end
      res[:payload]
    end

    module_function :cached
  end
end
