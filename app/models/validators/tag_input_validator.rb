# frozen_string_literal: true

class TagInputValidator < ActiveModel::Validator
  def validate(record)
    tags = record.tag_input.split(',').map { |t| t.strip.downcase }.uniq

    if Booru::CONFIG.settings[:tags][:min_count] && Booru::CONFIG.settings[:tags][:min_count] > tags.size
      record.errors[:base] << I18n.t('images.errors.tags_min_limit_not_met', limit: Booru::CONFIG.settings[:tags][:min_count])
    elsif Booru::CONFIG.settings[:tags][:max_count] && tags.size > Booru::CONFIG.settings[:tags][:max_count]
      record.errors[:base] << I18n.t('images.errors.tags_max_limit_not_met', limit: Booru::CONFIG.settings[:tags][:max_count])
    elsif Booru::CONFIG.settings[:tags][:bad_words].any? { |bad| tags.include? bad }
      record.errors[:base] << I18n.t('images.errors.tags_include_bad_words')
    end

    rating_tags = Booru::CONFIG.tag[:rating_tags] & tags
    record.errors[:base] << I18n.t('images.errors.tags_no_ratings_html').html_safe if rating_tags.empty?
  end
end
