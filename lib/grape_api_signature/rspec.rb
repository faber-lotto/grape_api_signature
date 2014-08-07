module GrapeAPISignature
  module RSpec
    # remember the diff request spec vs. controller spec
    # a controller spec offers a request object, a request spec
    # doesn't why ever
    def post_with_auth(path, parameters = nil, headers_or_env = {})
      headers_or_env.merge! sign_request('POST', path, parameters)

      # convert the body or ActionDispatch::Integration::RequestHelpers
      # enforces content type application/x-www-form-urlencoded
      # https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/testing/integration.rb#L286
      body = parameters.to_json
      post path, body, headers_or_env.merge('Content-Type' => 'application/json')
    end

    def get_with_auth(path, parameters = nil, headers_or_env = {})
      headers_or_env.merge! sign_request('GET', path, parameters)
      get path, parameters, headers_or_env # .merge('Content-Type' => 'application/json')
    end

    def sign_request(method, path, parameters = nil)
      if parameters.present?
        body = parameters.to_json
      else
        body = ''
      end

      headers_or_env = {
        'x-amz-date' => ::GrapeAPISignature::AWSRequest.formatted_time(Time.now),
        'ACCEPT' => 'application/json'
      }

      signer = ::GrapeAPISignature::AWSSigner.new(
          access_key: access_key,
          secret_key: secret_key,
          region: 'europe'
      )

      (hostname, port) = host.split(':')

      uri = URI(path)
      uri.host ||= hostname
      uri.scheme ||= https? ? 'https' : 'http'
      uri.port ||= (port || (https? ? 443 : 80)).to_i

      signer.sign(method, uri, headers_or_env, body).each_with_object({}) { |(k, v), new_h| new_h["HTTP_#{k.upcase}"] = v  }
    end
  end
end
