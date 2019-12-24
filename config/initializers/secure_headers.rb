# frozen_string_literal: true

SecureHeaders::Configuration.default do |config|
  config.cookies = {
    httponly: true,
    samesite: { lax: true },
    secure:   true
  }

  config.referrer_policy =                   'strict-origin-when-cross-origin'
  config.x_content_type_options =            'nosniff'
  config.x_download_options =                'noopen'
  config.x_frame_options =                   'SAMEORIGIN'
  config.x_permitted_cross_domain_policies = 'none'
  config.x_xss_protection =                  '1; mode=block'
  config.csp =                               SecureHeaders::OPT_OUT
end
