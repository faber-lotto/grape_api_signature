require 'unit_spec_helper'

module GrapeAPISignature
  describe AWSAuthParser do

    # rubocop:disable LineLength
    let(:aws_auth_str) { 'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host;p, Signature=debf546796015d6f6ded8626f5ce98597c33b47b9164cf6b17b4642036fcb592' }
    # rubocop:enable LineLength

    it 'parses an aws auth string' do
      expect(AWSAuthParser.parse(aws_auth_str)).not_to be_nil
    end

    it 'sets all aws auth values' do
      result = AWSAuthParser.parse(aws_auth_str)
      expect(result.access_key).to eq 'AKIDEXAMPLE'
      expect(result.date).to eq '20110909'
      expect(result.region).to eq 'us-east-1'
      expect(result.service).to eq 'host'
      expect(result.signed_headers).to eq %w(date host p)
      expect(result.signature).to eq 'debf546796015d6f6ded8626f5ce98597c33b47b9164cf6b17b4642036fcb592'
    end

  end
end
