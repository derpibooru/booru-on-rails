# frozen_string_literal: true

# A concern defining +scraped_image+ method for controllers that use
# +layouts/image_upload+ form and support remote image scraper uploads.
module ImageUpload
  # Returns URL to the scraped image or +nil+ if it's not present/an error occurs.
  # Yields a block with other scraped metadata (+author_name+, +source_url+)
  # if it has not set on the client side (via AJAX route).
  def scraped_image_url
    if scraper_cache.present?
      scraper_cache
    elsif scraper_url.present?
      scraped = Booru::Scraper.scrape(scraper_url)
      yield scraped if block_given?
      scraped.images[0].url.presence if scraped.images.present?
    end
  end

  # Returns a cached scraped URL. This param is used to determine if the scraper was
  # executed on the client side (via AJAX route) so as not to repeat potentially expensive
  # external queries.
  # Store this parameter in the model to preserve it on form reload.
  def scraper_cache
    params[:scraper_cache]
  end

  # Returns URL specified by user.
  # Store this parameter in the model to preserve it on form reload.
  def scraper_url
    params[:scraper_url]
  end
end
