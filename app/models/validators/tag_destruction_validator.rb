# frozen_string_literal: true

class TagDestructionValidator < ActiveModel::Validator
  def validate(tag)
    if tag.rating_tag?
      tag.errors.add(tag.name, I18n.t('tags.errors.destruction.rating_tag'))
    elsif Tag.where(aliased_tag_id: tag.id).any?
      tag.errors.add(tag.name, I18n.t('tags.errors.destruction.alias_target'))
    elsif Tag.joins(:implied_tags).where(tags_implied_tags: { implied_tag_id: tag.id }).any?
      tag.errors.add(tag.name, I18n.t('tags.errors.destruction.implied_by_others'))
    elsif Filter.where(system: true).where('spoilered_tag_ids @> ARRAY[?]', tag.id)
                .or(Filter.where(system: true).where('hidden_tag_ids @> ARRAY[?]', tag.id)).any?
      tag.errors.add(tag.name, I18n.t('tags.errors.destruction.in_system_filter'))
    elsif tag.namespace == 'spoiler'
      tag.errors.add(tag.name, I18n.t('tags.errors.destruction.namespace_spoiler'))
    end
  end
end
