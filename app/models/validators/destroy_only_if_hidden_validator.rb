# frozen_string_literal: true

# Validator for objects extending +Hidable+ and +Destroyable+ where it is
# desirable to enforce destroying content only after the object is hidden.
# This may always be the case, but this validator is implemented separately
# to promote separated concerns.
class DestroyOnlyIfHiddenValidator < ActiveModel::Validator
  def validate(record)
    return if !record.destroyed_content || record.hidden_from_users

    record.errors[:base] <<
      'Cannot destroy the content of ' \
      "#{record.class.model_name.human(count: 2)} without hiding first."
  end
end
