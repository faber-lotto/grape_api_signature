module GrapeAPISignature
  class AWSAuthParser
    attr_accessor :str, :authorization

    def self.parse(str)
      new(str).parse
    end

    def initialize(str)
      self.str = str
    end

    def parse
      self.authorization = AWSAuthorization.new(access_key, credential, signed_headers, signature)
    end

    def access_key
      credential_str.split('/', 2)[0]
    end

    def credential
      credential_str.split('/', 2)[1]
    end

    def signed_headers
      (params['SignedHeaders'] || '').split(';').map(&:strip)
    end

    def signature
      params['Signature'] || 'NOT_PROVIDED'
    end

    def credential_str
      params['Credential'] || 'NOT_PROVIDED/NOT_PROVIDED/NOT_PROVIDED/NOT_PROVIDED/NOT_PROVIDED'
    end

    def params
      @params ||= parse_params
    end

    def parse_params
      param_str.split(',').each_with_object({}) do |data, result|
        (key, value) = data.split('=')
        value ||= ''
        result[key.strip] = value.strip
      end
    end

    def sig_type
      @sig_type ||= str.split(' ', 2)[0]
    end

    def param_str
      @param_str ||= str.split(' ', 2)[1]
    end
  end
end
