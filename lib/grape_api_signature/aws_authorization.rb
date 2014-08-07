module GrapeApiSignature
  class AWSAuthorization
    attr_accessor :access_key,
                  :credential_string,
                  :signed_headers,
                  :signature

    attr_reader :date,
                :region,
                :service

    def initialize(access_key, credential_string, signed_headers, signature)
      self.access_key = access_key
      self.credential_string = credential_string
      self.signed_headers = signed_headers
      self.signature = signature
    end

    def to_s
      [
        "AWS4-HMAC-SHA256 Credential=#{access_key}/#{credential_string}",
        "SignedHeaders=#{signed_headers_str}",
        "Signature=#{signature}"
      ].join(', ')
    end

    def signed_headers=(signed_headers)
      @signed_headers = signed_headers.map(&:to_s).map(&:downcase).sort
    end

    def credential_string=(credential_string)
      @credential_string = credential_string || (['NOT_PROVIDED'] * 4).join('/')
      (@date, @region, @service, _) = @credential_string.split('/', 4)
    end

    def signed_headers_str
      signed_headers.join(';')
    end
  end
end
