# encoding: UTF-8
require 'openssl'
require 'time'
require 'uri'
require 'pathname'

module GrapeApiSignature
  module AWSDigester
    module_function

    def hexdigest(value)
      Digest::SHA256.new.update(value).hexdigest
    end

    def hmac(key, value)
      OpenSSL::HMAC.digest(digest, key, value)
    end

    def hexhmac(key, value)
      OpenSSL::HMAC.hexdigest(digest, key, value)
    end

    def digest
      OpenSSL::Digest.new('sha256')
    end
  end
end
