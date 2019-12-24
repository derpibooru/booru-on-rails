# frozen_string_literal: true

class ImageHashDuplicationValidator < ActiveModel::Validator
  def validate(record)
    if record.image_orig_sha512_hash.present? && !record.hidden_from_users
      duplicate = Image.where(image_orig_sha512_hash: record.image_orig_sha512_hash).where.not(id: record.id).first
      if duplicate
        message = "images.errors.hash_duplicate_found_#{'hidden_' if duplicate.hidden_from_users}html"
        record.errors[:base] << I18n.t(message, id: duplicate.id).html_safe
      end
    end
  end
end
