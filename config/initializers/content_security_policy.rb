# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

in_staging_or_production = Rails.env.staging? || Rails.env.production?

Rails.application.config.content_security_policy do |policy|
  policy.default_src     :self, 'https://derpicdn.net'
  policy.object_src      :none
  policy.frame_ancestors :none
  policy.frame_src       :none
  policy.form_action     :self
  policy.manifest_src    :self

  if in_staging_or_production
    policy.img_src :self, :data, 'https://derpicdn.net', 'https://camo.derpicdn.net'
  else
    policy.img_src '*', :data
  end

  policy.block_all_mixed_content

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
