require 'grape_api_signature/version'

require 'active_support'
require 'active_support/core_ext'

module GrapeAPISignature
  require 'grape_api_signature/signer_components'

  require 'grape_api_signature/middleware/auth'
  require 'grape_api_signature/middleware/grape_auth'

  require 'grape_api_signature/rails/engine'  if defined?(Rails)
end
