# frozen_string_literal: true

class BatchUpdateLogger < LoggerBase
  def self.log(user, tags, number_of_images)
    s = "[BATCH TAGGING] #{user} has tagged \"#{tags}\" on #{number_of_images} images"

    modfeed_send(s)
  end
end
