require 'unit_spec_helper'

module GrapeAPISignature
  describe Authorization do

    let(:request_method) { 'POST' }
    # rubocop:disable LineLength
    let(:headers) do
      {

        'Version' => 'HTTP/1.1',
        'Host' => 'localhost:3000',
        'Accept' => 'application/json',
        'Authorization' => 'AWS4-HMAC-SHA256 Credential=abc/20140730/europe/localhost/aws4_request, SignedHeaders=accept;content-type;x-amz-date, Signature=a358bdc1688e595c0f332aa7f7804a749d19908890e43e9e542a6c306190d079',
        'X-Amz-Date' => '20140730T131050Z',
        'X-Amz-Algorithm' => 'AWS4-HMAC-SHA256',
        'X-Amz-Signedheaders' => 'accept;content-type;x-amz-date',
        'Content-Type' => 'application/json'

      }

    end
    # rubocop:enable LineLength

    let(:uri) { URI('http://localhost:3000/api.json') }
    let(:body) { 'param1=param2, param3, param4' }

    subject do
      GrapeAPISignature::Authorization.new(
          request_method,
          headers,
          uri,
          body
      ).tap { |auth| allow(auth).to receive(:request_too_old?).and_return(false) }
    end

    describe '#authentic?' do

      it 'returns "true" when the signature matches' do
        expect(subject.authentic?('12345678')).to be_truthy
      end

      it 'returns "false" when the signature does not match' do
        expect(subject.authentic?('01234567')).to be_falsey
      end

      it 'returns "false" when the signature does match but time is up' do
        allow(subject).to receive(:request_too_old?).and_return(true)
        expect(subject.authentic?('12345678')).to be_falsey
      end

    end

    describe '#request_too_old?' do
      let(:datetime) { Time.now }

      subject do
        GrapeAPISignature::Authorization.new(
            request_method,
            headers,
            uri,
            body
        )
      end

      it 'returns "false" when 900 seks are not gone' do
        subject.headers['date'] = Time.now
        expect(subject.request_too_old?).to be_falsy
      end

      it 'returns "true" when 900 seks are gone' do
        subject.headers['date'] = Time.now - 901
        expect(subject.request_too_old?).to be_truthy
      end

    end

  end
end
