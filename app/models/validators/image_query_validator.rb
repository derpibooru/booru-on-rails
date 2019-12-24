# frozen_string_literal: true

class ImageQueryValidator < ActiveModel::Validator
  def validate(record)
    options[:fields].each do |p|
      next if record.changes_to_save[p.to_s].nil? # only check if changed,
      next if record[p].blank?                    # and present

      begin
        record.class.test_user_query_program(record[p], Image, user: User.new, is_mod: false)
      rescue SearchParsingError
        record.errors.add(p, "Could not parse search string '#{record[p]}'")
      end
    end
  end
end
