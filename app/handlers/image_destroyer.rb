# frozen_string_literal: true

class ImageDestroyer
  def initialize(image)
    @image = image
  end

  def save
    @image.image.nuke_image_files!
    @image.update(destroyed_content: true)

    ImageCloudflarePurgeJob.perform_later(@image.id)
    @image.update_index

    true
  end
end
