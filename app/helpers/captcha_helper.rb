# frozen_string_literal: true

module CaptchaHelper
  def captcha_tags
    render partial: 'layouts/captcha'
  end
end
