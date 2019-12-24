# frozen_string_literal: true

class AdvertsController < ApplicationController
  skip_authorization_check

  def show
    advert = Advert.find(params[:id])
    advert.increment!(:clicks)
    redirect_to advert.link
  end
end
