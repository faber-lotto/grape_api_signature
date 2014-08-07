require 'grape_api_signature/rspec'

RSpec.configure do |config|
  config.include GrapeAPISignature::RSpec, type: :request, file_path: /spec\/acceptance\/api/
end
