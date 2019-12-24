# frozen_string_literal: true

module RetardFilter
  # TODO: Remove when 1CJB stops ban evading
  def self.get_1cjb_score(text)
    sane_text = text.downcase.gsub(/[[:space:]]+/i, ' ').gsub(/[^a-z\d,. ]/i, '')

    # Algorithm is for us to know and 1CJB not to find out :^)
    score = 0

    score
  end

  def self.is_1cjb(text)
    get_1cjb_score(text) > 6
  end
end
