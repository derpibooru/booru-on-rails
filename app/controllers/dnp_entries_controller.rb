# frozen_string_literal: true

class DnpEntriesController < ApplicationController
  include UserQuery
  skip_authorization_check only: [:index]
  before_action :load_dnp_entry, only: [:show]

  # GET /dnp
  # Main list
  def index
    @title = 'Do-Not-Post List'
    if current_user && params[:show] == 'mine'
      @dnp_entries = DnpEntry.where('requesting_user_id = ?', current_user.id).order('created_at asc').page(params[:page]).per(50)
      @status_column = true
    else
      @dnp_entries = DnpEntry.where(aasm_state: 'listed').joins(:tag).order('tags.name_in_namespace asc').page(params[:page]).per(50)
    end
  end

  # GET /dnp/1
  # Show specific entry
  def show
    @title = "DNP Listing for #{@dnp_entry.tag.name}"
    authorize! :read, @dnp_entry
    @show_reason = !@dnp_entry.hide_reason || (current_user == @dnp_entry.requesting_user) || (current_user && current_user.can?(:manage, DnpEntry))
    @show_feedback = (current_user == @dnp_entry.requesting_user) || (current_user && current_user.can?(:manage, DnpEntry))
    respond_to do |format|
      format.html { render }
      format.json { render json: @dnp_entry.to_json(true) }
    end
  end

  # GET /dnp/new
  # New DNP entry form
  def new
    @title = 'New DNP Entry'
    authorize! :create, DnpEntry
    @dnp_entry = DnpEntry.new
    @dnp_types = Booru::CONFIG.dnp_types

    # Is a staff member trying to create an out-of-band DNP?
    @admin_tag_id = params[:tag_id].presence if current_user.can?(:manage, DnpEntry)
    @selectable_tags = if @admin_tag_id
      Tag.where(id: @admin_tag_id)
    else
      current_user.linked_tags
    end
  end

  # POST /dnp
  # Submit new DNP request
  def create
    authorize! :create, DnpEntry
    @dnp_entry = DnpEntry.new(dnp_entry_params)
    @dnp_entry.requesting_user = current_user
    @selectable_tags = Tag.where(id: @dnp_entry.tag_id)
    if @dnp_entry.save
      redirect_to @dnp_entry, notice: t('dnp.request_submitted')
    else
      render action: 'new'
    end
  end

  private

  # Load entry
  def load_dnp_entry
    @dnp_entry = DnpEntry.find(params[:id])
  end

  # Entry parameters
  def dnp_entry_params
    params.permit(:tag_id, :conditions, :reason, :hide_reason, :instructions, :feedback, :dnp_type)
  end
end
