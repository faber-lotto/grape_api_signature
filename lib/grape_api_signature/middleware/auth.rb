require 'uri'
require 'rack/auth/abstract/handler'

module GrapeAPISignature
  module Middleware
    class Auth < Rack::Auth::AbstractHandler
      attr_accessor :app, :max_request_age, :authenticator, :env

      def self.default_authenticator(&block)
        @default_authenticator = block if block_given?

        @default_authenticator
      end

      def initialize(app, max_request_age = 900, &authenticator)
        self.app = app
        self.authenticator = authenticator || self.class.default_authenticator
        self.max_request_age = max_request_age
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        self.env = env

        @auth_request = nil
        @auth = nil
        @authenticator_result = nil

        return unauthorized unless auth_request.provided?

        return bad_request unless auth_request.aws4?

        if valid?
          on_valid
        else
          unauthorized
        end
      end

      protected

      def on_valid
        env['REMOTE_USER'] = auth.user_id
        app.call(env)
      end

      def auth
        @auth ||= Authorization.new(request.request_method,
                                    auth_request.headers.merge('Content-Type' => request.content_type),
                                    URI(request.url),
                                    auth_request.body,
                                    max_request_age)
      end

      def auth_request
        @auth_request ||= AuthRequest.new(env)
      end

      def  request
        auth_request.request
      end

      def challenge
        'AWS4-HMAC-SHA256'
      end

      def valid?
        secret_key && auth.authentic?(secret_key)
      end

      def secret_key
        authenticator_result
      end

      def authenticator_result
        @authenticator_result ||= @authenticator.call(auth.user_id, auth.region, auth.service)
      end
    end
  end
end
