require 'rack/auth/abstract/request'
require 'rack/request'

module GrapeAPISignature
  module Middleware
    class AuthRequest < Rack::Auth::AbstractRequest
      def aws4?
        'AWS4-HMAC-SHA256'.downcase == scheme.downcase
      end

      def headers
        @headers ||= @env.each_with_object({}) do |(key, value), result_hash|
          key = key.upcase
          next unless key.to_s.start_with?('HTTP_') && (key.to_s != 'HTTP_VERSION')

          key = key[5..-1].gsub('_', '-').downcase.gsub(/^.|[-_\s]./) { |x| x.upcase }
          result_hash[key] = value
        end
      end

      def body
        @body ||= request.body.read.tap { request.body.rewind }
      end
    end
  end
end
