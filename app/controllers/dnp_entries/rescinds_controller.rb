# frozen_string_literal: true

class DnpEntries::RescindsController < ApplicationController
  before_action :load_dnp_entry, only: [:create]

  # POST /dnp/1/rescind
  # Rescinds a DNP request (yay!)
  def create
    authorize! :rescind, @dnp_entry
    @dnp_entry.rescind
    @dnp_entry.modifying_user = current_user
    @dnp_entry.save
    redirect_to @dnp_entry
  end

  private

  # Load entry
  def load_dnp_entry
    @dnp_entry = DnpEntry.find(params[:dnp_entry_id])
  end
end
