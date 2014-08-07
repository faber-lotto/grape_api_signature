require 'acceptance_spec_helper'
require 'rack/test'
require 'grape'

feature 'Authorize a grape api request' do
  include Rack::Test::Methods
  include Spec::Support::API

  def https?
    port == 443
  end

  let(:api) do
    key = secret_key

    Class.new(Grape::API) do
      Grape::Middleware::Auth::Strategies.add(:aws4_auth, GrapeApiSignature::Middleware::GrapeAuth, ->(options) { [options[:max_request_age] || 900, options[:user_setter]] } )

      GrapeApiSignature::Middleware::GrapeAuth.default_authenticator do |_user_id, _region, _service|
        {user: 'its me', secret_key: key }
      end

      helpers do
        attr_accessor :current_user
      end

      auth :aws4_auth, max_request_age: 100, user_setter: :'current_user=' ,&GrapeApiSignature::Middleware::GrapeAuth.default_authenticator
      get '/aws4_authorized' do
        'DONE'
      end
    end

  end

  let(:app) do
    api
  end

  let(:secret_key) { '12345678' }
  let(:access_key) { 'MyUser' }


  let(:hostname) { Rack::Test::DEFAULT_HOST }
  let(:port) { 80 }
  let(:host){ "#{hostname}:#{port}" }

  scenario 'authentication valid' do
    get_with_auth '/aws4_authorized'

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq '"DONE"'
  end

  scenario 'authentication not provided' do
    get '/aws4_authorized'

    expect(last_response.status).to eq 401
    expect(last_response.headers).to have_key 'WWW-Authenticate'
    expect(last_response.headers['WWW-Authenticate']).to eq 'AWS4-HMAC-SHA256'
    expect(last_response.body).to eq({error: 'Unauthorized'}.to_json)
  end

  scenario 'wrong schema' do
    get '/aws4_authorized', nil, 'HTTP_AUTHORIZATION' => 'Basic'

    expect(last_response.status).to eq 400
    expect(last_response.body).to eq({error: 'Bad Request'}.to_json)
  end

  scenario 'wrong signature' do
    get '/aws4_authorized', nil, 'HTTP_AUTHORIZATION' => 'AWS4-HMAC-SHA256 Credential='

    expect(last_response.status).to eq 401
    expect(last_response.headers).to have_key 'WWW-Authenticate'
    expect(last_response.headers['WWW-Authenticate']).to eq 'AWS4-HMAC-SHA256'
    expect(last_response.body).to eq({error: 'Unauthorized'}.to_json)
  end
end