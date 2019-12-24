# frozen_string_literal: true

class TagAliasValidator < ActiveModel::Validator
  def validate(tag)
    if tag.rating_tag?
      tag.errors.add :base, I18n.t('tags.errors.aliasing.base_rating_tag')
    elsif tag.aliases.any?
      aliases = tag.aliases.pluck(:name).map { |tag_name| "\"#{tag_name}\"" }.join(', ')
      tag.errors.add :base, I18n.t('tags.errors.aliasing.base_has_aliases', aliases: aliases)
    elsif tag.aliased_tag.nil?
      tag.errors.add :target_tag_name, I18n.t('tags.errors.aliasing.target_does_not_exist')
    elsif tag.aliased_tag.rating_tag?
      tag.errors.add :target_tag_name, I18n.t('tags.errors.aliasing.target_is_a_rating_tag')
    elsif tag.aliased_tag.id == tag.id
      tag.errors.add :target_tag_name, I18n.t('tags.errors.aliasing.target_identical_to_source')
    end
  end
end
