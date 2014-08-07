# encoding: UTF-8
require 'openssl'
require 'time'
require 'uri'
require 'pathname'

module GrapeAPISignature
  class AWSRequest
    RFC8601BASIC = '%Y%m%dT%H%M%SZ'

    attr_accessor :method, :uri, :headers, :body, :service, :digester

    def self.formatted_time(time)
      time.utc.strftime(RFC8601BASIC)
    end

    def initialize(method, uri, headers, body, digester = GrapeAPISignature::AWSDigester)
      self.method = method.upcase
      self.uri = uri
      self.headers = headers.each_with_object({}) { |(key, value), result_hash| result_hash[key.downcase] = value.strip }
      self.body = body
      self.service = uri.host.split('.', 2)[0]
      self.digester = digester
    end

    def canonical_request
      [
        method,
        clean_path,
        query_string,
        headers_as_str + "\n",
        headers.keys.sort.join(';'),
        digester.hexdigest(body || '')
      ].join("\n")
    end

    def datetime
      date_header = headers['date'] || headers['x-amz-date']
      self.class.formatted_time(date_header ? Time.parse(date_header) : Time.now)
    end

    def date
      datetime[0, 8]
    end

    protected

    def headers_as_str
      headers.sort.map { |k, v| [k, v].join(':') }.join("\n")
    end

    def clean_path
      path = Pathname.new(uri.path).cleanpath.to_s
      path << '/' if uri.path.end_with?('/') && !path.end_with?('/')
      path
    end

    def query_string
      return nil if uri.query.nil?
      uri.query.split('&').sort.join('&')
    end
  end
end
