# frozen_string_literal: true

module JsDatastore
  extend ActiveSupport::Concern

  included do
    helper_method :js_datastore
  end

  def js_datastore
    @js_datastore ||= default_clientside_data
  end

  private

  def default_clientside_data
    {
      'filter-id'            => @current_filter.id,
      'hidden-filter'        => @current_filter.normalized_hidden_complex_str,
      'hidden-tag-list'      => @current_filter.hidden_tag_ids.to_json,
      'ignored-tag-list'     => (@ignoredtaglist ? @ignoredtaglist.map(&:id) : []).to_json,
      'interactions'         => (@interactions || []).to_json,
      'spoiler-type'         => (current_user&.spoiler_type || 'static'),
      'spoilered-filter'     => @current_filter.normalized_spoilered_complex_str,
      'spoilered-tag-list'   => @current_filter.spoilered_tag_ids.to_json,
      'user-can-edit-filter' => (can?(:edit, @current_filter) && current_user && @current_filter.user_id == current_user.id).to_s,
      'user-id'              => current_user&.id,
      'user-is-signed-in'    => (!current_user.nil?).to_s,
      'user-name'            => current_user&.name,
      'user-slug'            => current_user&.slug,
      'watched-tag-list'     => (current_user&.watched_tag_ids || []).to_json,
      'fancy-tag-edit'       => (!current_user || current_user.fancy_tag_field_on_edit).to_s,
      'fancy-tag-upload'     => (!current_user || current_user.fancy_tag_field_on_upload).to_s,
      'hide-staff-tools'     => (cookies['hidestaff'] == 'true').to_s
    }
  end
end
