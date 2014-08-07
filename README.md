[![Gem Version](https://badge.fury.io/rb/grape_api_signature.svg)](http://badge.fury.io/rb/grape_api_signature)
[![Build Status](https://travis-ci.org/faber-lotto/grape_api_signature.svg?branch=master)](https://travis-ci.org/faber-lotto/grape_api_signature)
[![Code Climate](https://codeclimate.com/github/faber-lotto/grape_api_signature.png)](https://codeclimate.com/github/faber-lotto/grape_api_signature)
[![Coverage Status](https://coveralls.io/repos/faber-lotto/grape_api_signature/badge.png?branch=master)](https://coveralls.io/r/faber-lotto/grape_api_signature?branch=master)

# GrapeAPISignature

`GrapeAPISignature` provides a [AWS 4 style](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html) 
Authentication middleware to be used with [grape](https://github.com/intridea/grape).

## Installation

Add this line to your application's Gemfile:

    gem 'grape_api_signature'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape_api_signature

## Usage

### In your API

Example usage:

```ruby
 
  class YourAPI < Grape::API
    Grape::Middleware::Auth::Strategies.add(:aws4_auth,
                                            GrapeAPISignature::Middleware::GrapeAuth,
                                            ->(options) { [options[:max_request_age] || 900, options[:user_setter]] })
     
    GrapeAPISignature::Middleware::GrapeAuth.default_authenticator do |_access_key, _region, _service|
     user = ... # find the user, this block is executed in the context of your Endpoint
     { user: user, secret_key: user.key }
    end
    
    helpers do
      attr_accessor :current_user
    end
    
    auth :aws4_auth,
        max_request_age: 100,
        user_setter: :'current_user=',
        &GrapeAPISignature::Middleware::GrapeAuth.default_authenticator
    
    get '/aws4_authorized' do
     'DONE'
    end
  end
  
 ```
 
Options: 
 
 * `max_request_age` => Time in seconds how long a request is valid
 * `user_setter` => When provided this is be used to set the user on your Endtpoint instance if the validations was 
 successful 
 
If the validation was successful `env['REMOTE_USER']` is set to the access_key.
 
If the validation was not successful HTTP-Status 401 is set via `Grape#error!` 
when the signature was wrong and 400 if `Scheme` does not match 'AWS4-HMAC-SHA256'
 
### In your rspecs
 
 The following code only supports 'application/json' as Content-Type.
 
 ```ruby
 
 # spec_helper.rb
 
 require 'grape_api_signature/rspec'
 
 # in your spec
 
 describe 'your wishes' do
   include GrapeAPISignature::RSpec
   
   let(:secret_key) { 'SUPERSUPERSUPERSECRET' }
   let(:access_key) { 'MyUser' }
   
   
   # if you don't use Rails
   let(:hostname) { Rack::Test::DEFAULT_HOST }
   let(:port) { 80 }
   let(:host) { "#{hostname}:#{port}" }
   
   def https?
     port == 443
   end
   
   it 'should do' do
      get_with_auth '/'
   end
   
   it 'should also do' do
     post_with_auth '/', request_params
   end
   
 end
 
 ```
 
### In your Rails-App

This gem provides a coffee script to authenticate swagger demo requests via AWS 4.

```ruby

# application.js.coffee

#= require aws-signature

```

```html
# your swagger index.html, or what you use

<div id="header">
  <div class="swagger-ui-wrap">
    <form id="api_selector">
      <div class="input">
        <input type="text" placeholder="Username" id="input_apiUser" name="user">
      </div>
      <div class="input">
        <input type="password" placeholder="Password" id="input_apiPassword" name="password">
      </div>
    </form>
   </div>
</div>

```

## Contributing

1. Fork it ( https://github.com/faber-lotto/grape_api_signature/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
