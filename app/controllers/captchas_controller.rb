# frozen_string_literal: true

require 'captcha'

class CaptchasController < ApplicationController
  skip_authorization_check only: [:create]

  def create
    # This captcha solution can be used for 10 minutes.
    @captcha = Captcha.new

    respond_to do |format|
      format.js  { render }
      format.any { head 406 }
    end
  end
end
