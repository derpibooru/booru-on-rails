# frozen_string_literal: true

require 'carrierwave/dragonfly_record_compatibility'
require 'carrierwave/image_analyzers'
require 'carrierwave/image_processors'
require 'carrierwave/image_validations'

CarrierWave.configure do |c|
  c.root = if Rails.env.test?
    Rails.root.join('public', 'test')
  else
    capistrano_shared = Rails.root.to_s.gsub(/\/releases\/\d+/, '/shared').to_s
    "#{capistrano_shared}/public"
  end

  c.ignore_integrity_errors = true
  c.ignore_processing_errors = Rails.env.production?
  c.ignore_download_errors = Rails.env.production?

  c.permissions = 0o644
end
