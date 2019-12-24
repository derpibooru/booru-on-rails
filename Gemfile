# frozen_string_literal: true

source 'https://rubygems.org'

# Rails
gem 'rails', '6.0.0.rc1'
gem 'bootsnap', require: false
gem 'nokogiri'
gem 'jsonapi-rails'
gem 'composite_primary_keys', '12.0.0.rc5'

# Database
gem 'pg'
gem 'paper_trail'
gem 'kaminari' # needs to be included before elasticsearch gems
gem 'database_validations'

# Redis
gem 'hiredis'
gem 'redis-rails'

# Elasticsearch
gem 'elasticsearch-model'
gem 'elastic-apm'
gem 'model-msearch'

# Image processing
gem 'carrierwave'
gem 'mini_magick'
gem 'rb-libmagic'
gem 'image_intensities'

# Authentication/authorization
gem 'devise'
gem 'devise-two-factor', github: 'liamwhite/devise-two-factor', ref: '0e127c6'
gem 'devise-pwned_password'
gem 'rolify'
gem 'can4'

# Views
gem 'slim'
gem 'slim-rails'
gem 'differ'
gem 'flipper'
gem 'flipper-redis'
gem 'flipper-ui'
gem 'secure_headers'
gem 'rqrcode'

# Assets
gem 'sassc-rails'
gem 'font-awesome-sass'
gem 'autoprefixer-rails'
gem 'normalize-rails'
gem 'uglifier'
gem 'sprockets-rollup'

# Library
gem 'chronic'
gem 'simple_git'
gem 'rest-client'
gem 'addressable' # Ruby's URI implementation sucks
gem 'aasm'
gem 'twitter', github: 'liamwhite/twitter', ref: '0a9a18f'
gem 'twitch-api'

# Programs
gem 'puma'
gem 'unicorn'
gem 'foreman'
gem 'eye'
gem 'sidekiq'
gem 'sidekiq-failures'

group :development do
  # Debug error page
  gem 'better_errors'
  gem 'binding_of_caller'

  # Debugger
  gem 'byebug'

  # Linters
  gem 'rubocop-rails'
  gem 'slim_lint'
  gem 'brakeman'
end

group :test do
  # Factories
  gem 'factory_bot_rails'

  # Stubs out HTTP requests
  gem 'hashdiff', '1.0.0.beta1'
  gem 'webmock'
  gem 'vcr', require: false

  # Controller tests removed from rails
  gem 'rails-controller-testing'
end
