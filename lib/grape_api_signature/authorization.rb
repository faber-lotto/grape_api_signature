module GrapeAPISignature
  class Authorization
    attr_accessor :request_method, :headers, :body, :auth_header,
                  :uri, :secret_key, :authorization, :max_request_age_in_sec

    def initialize(request_method, headers, uri, body, max_request_age_in_sec = 900)
      self.request_method = request_method.upcase
      self.headers = headers.each_with_object({}) { |(key, value), result_hash| result_hash[key.downcase] = value }
      self.body = body
      self.auth_header = {}
      self.uri = uri
      self.max_request_age_in_sec = max_request_age_in_sec
      self.authorization = GrapeAPISignature::AWSAuthParser.parse(self.headers['authorization']) if auth_header?
    end

    def user_id
      authorization.access_key
    end

    def region
      authorization.region
    end

    def service
      authorization.service
    end

    def datetime
      (headers['date'] || headers['x-amz-date'] || max_request_age - 1).to_time
    end

    def signed_headers
      return {} unless authorization.signed_headers.present?
      headers.slice(*authorization.signed_headers)
    end

    def calculated_signature(secret_key)
      signer = GrapeAPISignature::AWSSigner.new(
          access_key: user_id,
          secret_key: secret_key,
          region: authorization.region
      )

      signer.signature_only(request_method, uri, signed_headers, body)
    end

    def auth_header?
      headers['authorization'].present?
    end

    def authentic?(secret_key)
      return false if secret_key.nil?

      auth_header? && signatures_match?(secret_key) && !request_too_old?
    end

    def signatures_match?(secret_key)
      authorization.signature.present? && secure_compare(calculated_signature(secret_key), authorization.signature)
    end

    def request_too_old?
      datetime.utc < max_request_age
    end

    def max_request_age
      Time.now.utc - max_request_age_in_sec
    end

    def secure_compare(a, b)
      return false unless a.to_s.bytesize == b.to_s.bytesize

      l = a.unpack 'C*'

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end
end
