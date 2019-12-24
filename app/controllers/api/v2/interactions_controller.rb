# frozen_string_literal: true

class Api::V2::InteractionsController < Api::V2::ApiController
  skip_authorization_check

  before_action :filter_banned_users
  before_action :require_user
  before_action :load_interactable, only: [:vote, :fave, :hide]
  before_action :load_many_interactables, only: [:interacted]

  def vote
    case params[:value]
    when 'up'
      @interactable.votes.create(user: current_user, up: true)
    when 'down'
      @interactable.votes.create(user: current_user, up: false)
    when 'false'
      @interactable.votes.where(user: current_user).destroy_all
    end

    @interactable.update_index

    render json: return_values(@interactable)
  end

  def fave
    if params[:value] == 'true'
      @interactable.faves.create(user: current_user)
      @interactable.votes.create(user: current_user, up: true)
    else
      @interactable.faves.where(user: current_user).destroy_all
    end

    @interactable.update_index

    render json: return_values(@interactable)
  end

  def hide
    if params[:value] == 'true'
      @interactable.hides.create(user: current_user)
    else
      @interactable.hides.where(user: current_user).destroy_all
    end

    @interactable.update_index
    render json: return_values(@interactable)
  end

  def interacted
    render json: (@interactions || []).to_json
  end

  private

  def load_interactable
    @interactable = Image.find_by hidden_from_users: false, id: params[:id]
    head(:not_found) if @interactable.nil?
  end

  def load_many_interactables
    @interactable_ids = (params[:ids].split(',')
                                     .map { |x| Integer(x) rescue false }
                                     .compact
                                     .uniq[0..49] rescue nil)
    if @interactable_ids
      @interactions = ImageQuery.interactions(@interactable_ids, current_user.id)
    else
      head :bad_request
    end
  end

  #
  # Returns the values that should be sent back to whoever just did some favin'/votin'
  # @param  interactable [Interactable] the thing to get data from
  #
  # @return [Hash] a ready-for-JSON serialized set of values
  def return_values(interactable)
    {
      score:      interactable.score,
      favourites: interactable.faves_count,
      upvotes:    interactable.upvotes_count,
      downvotes:  interactable.downvotes_count,
      votes:      -1
    }
  end
end
