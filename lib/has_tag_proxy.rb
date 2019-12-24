# frozen_string_literal: true

module HasTagProxy
  def has_tag_proxy(on:, name:)
    define_method(name) do
      Tag.where(id: self[on]).order(name: :asc).pluck(:name).join(', ')
    end

    define_method("#{name}=") do |val|
      # FIXME: using #[]= fucks with HasArrayField, but would be much nicer here
      send "#{on}=", Tag.where(name: Tag.parse_tag_list(val)).pluck(:id)
    end
  end
end

ActiveRecord::Base.send(:extend, HasTagProxy)
