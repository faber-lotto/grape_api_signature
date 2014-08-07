#
# taken from https://github.com/jnicklas/capybara/blob/master/lib/capybara/rspec/features.rb
#
module Capybara
  module Features
    def self.included(base)
      base.instance_eval do
        # rubocop:disable Alias
        alias :background :before
        alias :scenario :it
        alias :xscenario :xit
        alias :given :let
        alias :given! :let!
        alias :feature :describe
        # rubocop:enable Alias
      end
    end
  end
end

def self.feature(*args, &block)
  options = args.last.is_a?(Hash) ? args.pop : {}
  options[:capybara_feature] = true
  options[:type] = :feature
  options[:caller] ||= caller
  args.push(options)

  describe(*args, &block)
end

RSpec.configuration.include Capybara::Features, capybara_feature: true
