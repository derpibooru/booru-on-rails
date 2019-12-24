# frozen_string_literal: true

class AdvertSelector
  # Selects an advert to display for the given image, taking restrictions into account
  # If no image is given, only ads with no restrictions are returned
  def self.for(image)
    restrictions = ['none']
    if image && nsfw?(image)
      # If we're NSFW allow those
      restrictions << 'nsfw'
    elsif image && safe?(image)
      # Same deal for SFW
      restrictions << 'sfw'
    end
    ads = Advert.where(live: true, restrictions: restrictions).where('start_date < :t AND finish_date > :t', t: Time.zone.now).all.to_a
    ads.sample
  end

  # Is this image NSFW?
  def self.nsfw?(image)
    (image.tag_ids & nsfw_rating_ids).any?
  end

  # Used mainly for con ads who don't want their ads on dodgy material
  def self.safe?(image)
    (image.tag_ids & sfw_rating_ids).any?
  end

  def self.nsfw_rating_ids
    @nsfw_rating_ids ||= Tag.where(name: Booru::CONFIG.tag[:nsfw_ratings]).pluck(:id)
  end

  def self.sfw_rating_ids
    @sfw_rating_ids ||= Tag.where(name: %w[safe suggestive]).pluck(:id)
  end
end
