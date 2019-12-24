# frozen_string_literal: true

class Admin::DnpEntries::TransitionsController < ApplicationController
  before_action :check_auth
  before_action :load_dnp_entry

  # POST /admin/dnp_entry/1/transition
  # Changes state of a request
  def create
    case params[:do]
    when 'claim'
      @dnp_entry.claim
    when 'list'
      @dnp_entry.list
    when 'rescind'
      @dnp_entry.rescind
    when 'acknowledge'
      @dnp_entry.acknowledge
    when 'close'
      @dnp_entry.close
    end

    @dnp_entry.modifying_user = current_user
    @dnp_entry.save

    redirect_to admin_dnp_entries_path
  end

  private

  def load_dnp_entry
    @dnp_entry = DnpEntry.find(params[:dnp_entry_id])
  end

  def check_auth
    authorize! :manage, DnpEntry
  end
end
