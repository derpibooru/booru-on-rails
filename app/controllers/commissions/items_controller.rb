# frozen_string_literal: true

class Commissions::ItemsController < ApplicationController
  before_action :filter_banned_users
  before_action :load_commission
  before_action :load_commission_item, only: [:edit, :update, :destroy]
  before_action :check_auth

  # GET /commissions/BobRoss/items/new
  # Shows the new item form
  def new
    @title = 'Add Item'
    @commission_item = CommissionItem.new
  end

  def create
    @commission_item = @commission.commission_items.build(item_params)

    if @commission_item.save
      redirect_to commission_path(@commission), notice: t('commissions.item_added')
    else
      render :new
    end
  end

  def edit
    @title = "Edit Item: #{@commission_item.item_type}"
  end

  def update
    if @commission_item.update(item_params)
      redirect_to commission_path(@commission), notice: t('commissions.item_edited')
    else
      render :edit
    end
  end

  def destroy
    @commission_item.destroy

    redirect_to commission_path(@commission), notice: t('commissions.item_deleted')
  end

  private

  def load_commission
    @user = User.find_by!(slug: params[:commission_id])
    @commission = Commission.find_by!(user: @user)
  end

  def load_commission_item
    @commission_item = CommissionItem.find(params[:id])
  end

  def check_auth
    authorize! :edit, @commission
  end

  def item_params
    params.require(:commission_item).permit(:item_type, :description, :base_price, :add_ons, :example_image_id)
  end
end
