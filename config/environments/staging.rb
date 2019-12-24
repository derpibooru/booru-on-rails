# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Match production env as close as possible while keeping extensive (debug-level) logging.
  config.log_level = :debug
  config.log_tags = [:request_id]
  config.log_formatter = ::Logger::Formatter.new

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  else
    config.logger = ActiveSupport::TaggedLogging.new(
      ActiveSupport::Logger.new('/home/derpibooru/shared/log/staging.log')
    )
    config.colorize_logging = false
  end

  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.active_support.deprecation = :notify
  config.active_record.dump_schema_after_migration = false
  config.i18n.fallbacks = true

  # Disable serving static files since NGINX already handles this.
  config.public_file_server.enabled = false

  config.assets.digest = true
  config.assets.compress = true
  config.assets.css_compressor = :yui
  config.assets.js_compressor = :closure
  config.assets.compile = false

  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  config.action_controller.asset_host = Booru::CONFIG.settings[:cdn_url_root]

  # Disable rack::cache, we're using varnish!
  config.action_dispatch.rack_cache = nil
  config.cache_store = :redis_store, 'redis://localhost:6379/0/derp', { expires_in: 5.days }

  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default charset: 'utf-8'
  config.action_mailer.default_url_options = { host: Booru::CONFIG.settings[:public_host] }
end
