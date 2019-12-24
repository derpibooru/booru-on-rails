# frozen_string_literal: true

module AnonyHash
  def anonymous_user_and_hash(object)
    "#{I18n.t('booru.anonymous_user')} ##{get_anony_hash(object)}"
  end

  def get_anony_hash(object)
    salt = Booru::CONFIG.settings[:anonyhash_salt].to_s
    id = [object.try(:parent_id), object.id].detect(&:present?)
    identifier = object.best_user_identifier
    "%04X" % (Zlib.crc32(salt + id.to_s + identifier.to_s) & 0xffff)
  end
end
