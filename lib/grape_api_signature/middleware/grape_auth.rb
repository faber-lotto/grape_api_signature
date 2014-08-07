require 'uri'
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'
require 'rack/request'

module GrapeApiSignature
  module Middleware
    class GrapeAuth < GrapeApiSignature::Middleware::Auth

      attr_accessor :user_setter

      def initialize(app, max_request_age=900, user_setter=:'current_user=' ,&authenticator)
        super(app, max_request_age, &authenticator)
        self.user_setter = user_setter
      end

      protected

      def endpoint
        env['api.endpoint']
      end

      def on_valid
        endpoint.send(user_setter, user) if user_setter
        super
      end

      def secret_key
        authenticator_result[:secret_key]
      end

      def user
        authenticator_result[:user]
      end

      def unauthorized(www_authenticate = challenge)
        endpoint.error!({ error: 'Unauthorized' }, 401 , { 'WWW-Authenticate' => www_authenticate.to_s })
      end

      def bad_request
        endpoint.error!({ error: 'Bad Request' }, 400)
      end

    end
  end
end