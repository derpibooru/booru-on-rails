# frozen_string_literal: true

class Admin::ModNotesController < ApplicationController
  include UserQuery
  before_action :check_authorization
  before_action :setup_note, only: [:new, :create]

  def index
    @title = 'Admin - Mod Notes'
    @notes = if params[:q]
      @query = params[:q]
      ModNote.where('body ILIKE ?', '%' + @query + '%')
    else
      ModNote
    end.order(created_at: :desc).page(params[:page]).per(50)
  end

  def new
    @title = 'New Mod Note'
  end

  def create
    @mod_note.moderator = @current_user
    @mod_note.body = params[:mod_note][:body]
    @mod_note.save!
    redirect_to admin_mod_notes_path
  end

  def destroy
    @mod_note = ModNote.find(params[:id])
    @mod_note.destroy!
    redirect_to admin_mod_notes_path
  end

  def edit
    @mod_note = ModNote.find(params[:id])
    @title = 'Editing Mod Note'
  end

  def update
    @mod_note = ModNote.find(params[:id])
    @mod_note.update(body: params[:mod_note][:body])
    redirect_to admin_mod_notes_path
  end

  private

  def check_authorization
    !authorize! :manage, ModNote
  end

  def setup_note
    if (@notable = find_notable)
      @mod_note = @notable.mod_notes.new(notable_id: params[:notable_id])
    else
      respond_to do |format|
        format.html { flash[:notice] = 'Unable to create note for this object.'; redirect_to root_path }
        format.js { render plain: 'Unable to create note', layout: false }
      end
    end
  end

  def find_notable
    # TODO: Requires special-casing DnpEntry, consider whitelisting
    notable_class = params[:notable_class] == 'DnpEntry' ? DnpEntry : params[:notable_class].capitalize.safe_constantize
    return false unless notable_class < Notable

    @notable = notable_class.find_by(id: params[:notable_id])
  end
end
