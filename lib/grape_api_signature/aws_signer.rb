# encoding: UTF-8
require 'openssl'
require 'time'
require 'uri'
require 'pathname'

module GrapeApiSignature
  class AWSSigner
    attr_accessor :access_key, :secret_key, :region, :digester
    attr_accessor :request

    def initialize(config)
      self.access_key = config[:access_key]
      self.secret_key = config[:secret_key]
      self.region = config[:region]
      self.digester = config[:digester] || AWSDigester
    end

    def setup_aws_request(method, uri, headers, body)
      self.request = AWSRequest.new(method, uri, headers, body, digester)
    end

    def sign(method, uri, headers, body)
      setup_aws_request(method, uri, headers, body)

      signed = headers.dup
      signed['Authorization'] = authorization(headers)
      signed
    end

    def signature_only(method, uri, headers, body)
      setup_aws_request(method, uri, headers, body)
      signature
    end

    def authorization(headers)
      AWSAuthorization.new(access_key, credential_string, signed_headers(headers), signature).to_s
    end

    def signed_headers(headers)
      to_sign = headers.keys.map(&:to_s).map(&:downcase)
      to_sign.delete('authorization')
      to_sign
    end

    def signature
      digester.hexhmac(derived_key, string_to_sign)
    end

    def derived_key
      k_date = digester.hmac('AWS4' + secret_key, request.date)
      k_region = digester.hmac(k_date, region)
      k_service = digester.hmac(k_region, request.service)

      digester.hmac(k_service, 'aws4_request')
    end

    def string_to_sign
      [
        'AWS4-HMAC-SHA256',
        request.datetime,
        credential_string,
        digester.hexdigest(request.canonical_request)
      ].join("\n")
    end

    def credential_string
      [
        request.date,
        region,
        request.service,
        'aws4_request'
      ].join('/')
    end
  end
end
