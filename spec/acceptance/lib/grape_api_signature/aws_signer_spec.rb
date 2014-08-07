require 'acceptance_spec_helper'
require 'thin'

module GrapeAPISignature
  describe AWSSigner, :aws_helpers do

    Dir[File.join(Spec::Support::AWSHelper.suite_dir, '*.req')].each do |f|

      filename = File.basename(f, '.req')

      let(:secret_key) { 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY' }
      let(:id) { 'AKIDEXAMPLE' }
      let(:region) { 'us-east-1' }
      let(:host) { 'host' }

      let(:subject)do
        GrapeAPISignature::AWSSigner.new(
           access_key: id,
           secret_key: secret_key,
           region: region
        )
      end

      describe "testcase #{filename}" do
        let(:request_str) { File.read(f).gsub('http/1', 'HTTP/1') }
        let(:str_to_sign) { File.read(File.join(Spec::Support::AWSHelper.suite_dir, "#{filename}.sts")).gsub("\r\n", "\n") }
        let(:auth_header) { File.read(File.join(Spec::Support::AWSHelper.suite_dir, "#{filename}.authz")) }

        let(:request) { request_for_str(request_str) }

        let(:uri) do
          begin
            URI(request.url)
          rescue URI::InvalidURIError
            URI(URI.encode(request.url))
          end
        end
        let(:headers) { headers_from_env(request.env) }
        let(:body) { request.body.read }

        it 'creates the expected string to sign' do
          subject.setup_aws_request(request.request_method, uri, headers, body)
          expect(subject.string_to_sign).to eq str_to_sign
        end

        it 'creates the expected signature' do
          signature = subject.sign(request.request_method, uri, headers, body)
          expect(signature['Authorization']).to eq auth_header
        end

      end
    end
  end
end
