# frozen_string_literal: true

class Admin::AdvertsController < ApplicationController
  before_action :check_auth
  before_action :load_advert, only: [:show, :edit, :update, :destroy]

  def index
    @title = 'Admin - Adverts'
    @adverts = Advert.order(finish_date: :desc).page(params[:page]).per(25)

    respond_to do |format|
      format.html
      format.json { render json: @adverts }
    end
  end

  def show
    # Not currently implemented
    @title = "Advert History - #{@advert.title}"
    redirect_to admin_adverts_path, error: 'History not available'
  end

  def new
    @title = 'New Advert'
    @advert = Advert.new
    respond_to do |format|
      format.html
      format.json { render json: @advert }
    end
  end

  def edit
    @title = "Editing Advert: #{@advert.title}"
  end

  def create
    @advert = Advert.new(advert_params)
    respond_to do |format|
      if @advert.save
        format.html { redirect_to admin_adverts_path, notice: 'Advert was successfully created.' }
        format.json { render json: @advert, status: :created, location: admin_adverts_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @advert.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @advert.update(advert_params)
        format.html { redirect_to admin_adverts_path, notice: 'Advert was successfully updated.' }
        format.json { render json: @advert, status: :created, location: admin_adverts_path }
      else
        format.html { render action: 'new' }
        format.json { render json: @advert.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @advert.destroy
    respond_to do |format|
      format.html { redirect_to admin_adverts_url }
      format.json { head :ok }
    end
  end

  private

  def load_advert
    @advert = Advert.find_by(id: params[:id])
  end

  def check_auth
    authorize! :manage, Advert
  end

  def advert_params
    params.require(:advert).permit(:uploaded_image, :link, :title, :start, :finish, :restrictions, :live, :notes)
  end
end
