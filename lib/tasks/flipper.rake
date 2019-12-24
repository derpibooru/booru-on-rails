# frozen_string_literal: true

# Hash of features and their defaults
# true: enabled, false: disabled
FEATURES = {
  april_fools:          false,
  camo_images:          true,
  image_optimisation:   true,
  image_uploads:        true,
  livestream_updates:   true,
  new_account_lock:     false,
  pwned_password_check: true,
  captcha:              true,
  site_interactivity:   true,
  webm_generation:      true
}.freeze

namespace :booru do
  namespace :features do
    desc 'set features so they can be enabled'
    task create: :environment do
      FEATURES.each_key do |feature|
        f = $flipper[feature]
        f.disable unless f.enabled?
      end
    end
    desc 'enable default features'
    task enable_defaults: :environment do
      FEATURES.each do |feature, enable|
        f = $flipper[feature]
        enable ? f.enable : f.disable
      end
    end
  end
end
