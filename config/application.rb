# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Other requires
require 'slim/include'
require 'sprockets/rollup'
require 'magic'
require 'openssl/digest'
require 'fileutils'
require 'set'
require 'simple_git'
require 'redis'
require 'redis/connection/hiredis'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BooruOnRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.hosts = nil
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.eager_load_paths.push "#{config.root}/app/models/validators"
    config.eager_load_paths.push "#{config.root}/lib"

    config.generators do |g|
      g.orm                 :active_record
      g.javascript_engine   :js
      g.view_specs          true
      g.helper_specs        false
      g.scaffold_stylesheet false
      g.stylesheets         false
      g.javascripts         false
    end

    config.active_job.queue_adapter = :sidekiq

    # Slim defaults to XHTML output - long live HTML5
    Slim::Engine.set_options format: :html

    # ElasticAPM has a lot of useless debug logging
    Rails.application.config.elastic_apm.alert_logger = Logger.new(nil)
    Rails.application.config.elastic_apm.logger = Logger.new(nil)

    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
