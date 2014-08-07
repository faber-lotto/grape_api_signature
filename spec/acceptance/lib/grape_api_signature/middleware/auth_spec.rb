require 'acceptance_spec_helper'
require 'rack/test'

feature 'Authorize a request' do
  include Rack::Test::Methods
  include Spec::Support::API

  let(:base_app) { ->(env) { [200, env, "app"] } }

  let(:app) do
    app = base_app
    key = secret_key
    Rack::Builder.app do
      use GrapeApiSignature::Middleware::Auth do |*|
        key
      end
      run app
    end
  end

  let(:secret_key) { '12345678' }
  let(:access_key) { 'MyUser' }


  let(:hostname) { Rack::Test::DEFAULT_HOST }
  let(:port) { 80 }
  let(:host){ "#{hostname}:#{port}" }

  def https?
    port == 443
  end

  scenario 'authentication valid' do
    get_with_auth '/'

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq 'app'
  end

  scenario 'authentication not provided' do
    get '/'

    expect(last_response.status).to eq 401
    expect(last_response.headers).to have_key 'WWW-Authenticate'
    expect(last_response.headers['WWW-Authenticate']).to eq 'AWS4-HMAC-SHA256'
  end

  scenario 'wrong schema' do
    get '/', nil, 'HTTP_AUTHORIZATION' => 'Basic'

    expect(last_response.status).to eq 400
  end

  scenario 'wrong signature' do
    get '/', nil, 'HTTP_AUTHORIZATION' => 'AWS4-HMAC-SHA256 Credential='

    expect(last_response.status).to eq 401
    expect(last_response.headers).to have_key 'WWW-Authenticate'
    expect(last_response.headers['WWW-Authenticate']).to eq 'AWS4-HMAC-SHA256'
  end
end