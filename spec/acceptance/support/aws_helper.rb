module Spec
  module Support
    module AWSHelper
      def headers_from_env(env)
        headers = {}
        headers['CONTENT-TYPE'] = env['CONTENT_TYPE'] if env.key?('CONTENT_TYPE')

        env.each_with_object(headers) do |(key, value), result_hash|
          next unless key.to_s.start_with?('HTTP_') && (key.to_s != 'HTTP_VERSION')

          key = key[5..-1].gsub('_', '-').downcase.gsub(/^.|[-_\s]./) { |x| x.upcase }
          result_hash[key] = value
        end
      end

      def request_for_str(str)
        thin_req = Thin::Request.new.tap { |r| r.parse(str) }
        Rack::Request.new(thin_req.env)
      end

      def self.suite_dir
        File.join(File.expand_path(__dir__), '../../fixtures/aws4_test_suite/pass')
      end
    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::AWSHelper, :aws_helpers
end
