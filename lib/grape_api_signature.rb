require 'grape_api_signature/version'

require 'active_support'
require 'active_support/core_ext'

module GrapeAPISignature
  require 'grape_api_signature/aws_digester'
  require 'grape_api_signature/aws_request'
  require 'grape_api_signature/aws_auth_parser'
  require 'grape_api_signature/aws_signer'
  require 'grape_api_signature/aws_authorization'
  require 'grape_api_signature/authorization'

  require 'grape_api_signature/middleware/auth'
  require 'grape_api_signature/middleware/grape_auth'

  require 'grape_api_signature/rails/engine'  if defined?(Rails)
end
