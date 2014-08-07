require 'acceptance_spec_helper'
require 'thin'

module GrapeAPISignature
  describe AWSRequest, :aws_helpers do

    Dir[File.join(Spec::Support::AWSHelper.suite_dir, '*.req')].each do |f|

      filename = File.basename(f, '.req')

      let(:id) { 'AKIDEXAMPLE' }
      let(:region) { 'us-east-1' }
      let(:host) { 'host' }

      let(:subject) { GrapeAPISignature::AWSRequest.new(request.request_method, uri, headers, body) }

      describe "testcase #{filename}" do
        let(:request_str) { File.read(f).gsub('http/1', 'HTTP/1') }
        let(:request) { request_for_str(request_str) }
        let(:canonical_request) { File.read(File.join(Spec::Support::AWSHelper.suite_dir, "#{filename}.creq")).gsub("\r\n", "\n") }

        let(:uri) do
          begin
            URI(request.url)
          rescue URI::InvalidURIError
            URI(URI.encode(request.url))
          end
        end
        let(:headers) { headers_from_env(request.env) }
        let(:body) { request.body.read }

        it 'creates the expected canonical_request' do
          expect(subject.canonical_request).to eq canonical_request
        end

      end
    end
  end
end
