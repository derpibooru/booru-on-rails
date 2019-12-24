# frozen_string_literal: true

class Api::V2::ImagesController < Api::V2::ApiController
  skip_authorization_check
  before_action :load_images

  def show
    @interactions = ImageQuery.interactions(@images.map(&:id).compact, current_user.id) if current_user
    render json: { images: @images.map(&:as_json), interactions: (@interactions || []) }
  end

  private

  def load_images
    @images = Image.where(id: select_ids(params[:ids]))
  end

  def select_ids(string)
    string.split(',').select { |x| Integer(x) rescue false }.compact.uniq[0..49] rescue nil
  end
end
