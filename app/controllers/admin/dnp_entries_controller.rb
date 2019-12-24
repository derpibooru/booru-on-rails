# frozen_string_literal: true

class Admin::DnpEntriesController < ApplicationController
  before_action :check_auth
  before_action :load_dnp_entry, except: [:index, :new, :create]

  # GET /admin/dnp_entry
  # Index page
  def index
    @title = 'Admin - DNP Entries'
    states = %w[requested claimed rescinded acknowledged]
    valid_states = %w[requested claimed listed rescinded acknowledged closed]
    states = params[:states].split(',') & valid_states if params[:states]
    @dnp_requests = if params[:q].present?
      DnpEntry.joins(:tag).joins(:requesting_user)
              .where('users.name ILIKE ? OR tags.name ILIKE ? OR reason ILIKE ? OR conditions ILIKE ? or instructions ILIKE ?',
                     "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
              .page(params[:page]).per(DnpEntry.admin_listings_per_page)
    else
      DnpEntry.where(aasm_state: states).order('updated_at desc').page(params[:page]).per(DnpEntry.admin_listings_per_page)
    end
  end

  # GET /admin/dnp_entry/1
  # Show DNP Request
  def show
    @title = "DNP Entry - #{@dnp_entry.tag.name}"
  end

  # GET /admin/dnp_entry/new
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

  # POST /admin/dnp_entry
  # Submit new DNP request
  def create
    authorize! :create, DnpEntry
    @dnp_entry = DnpEntry.new(dnp_entry_params)
    @dnp_entry.requesting_user = current_user
    @selectable_tags = Tag.where(id: @dnp_entry.tag_id)
    if @dnp_entry.save
      redirect_to admin_dnp_entry_path(@dnp_entry), notice: t('dnp.request_submitted')
    else
      render action: 'new'
    end
  end

  # GET /admin/dnp_entry/1/edit
  # Edit DNP request
  def edit
    @title = "Editing DNP Entry: #{@dnp_entry.tag.name}"
    authorize! :edit, @dnp_entry
    @selectable_tags = Tag.where(id: @dnp_entry.tag_id)
  end

  # PATCH /admin/dnp_entry/1
  # Save edits
  def update
    authorize! :edit, @dnp_entry
    @selectable_tags = Tag.where(id: @dnp_entry.tag_id)
    @dnp_entry.hide_reason = params[:hide_reason].present?
    if @dnp_entry.update(dnp_entry_params)
      redirect_to admin_dnp_entry_path(@dnp_entry), notice: t('dnp.request_updated')
    else
      render action: 'edit'
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

  # Check that user can manage DNP Entries
  def check_auth
    authorize! :manage, DnpEntry
  end
end
