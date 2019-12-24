# frozen_string_literal: true

require 'nokogiri'

DATA_URI_REGEX = /\Adata:(image\/png|image\/gif|image\/jpeg|image\/svg+xml);base64,/.freeze

module SVGScrubber
  # Removes any <script> tags in SVG files.
  def self.scrub(path)
    svg = Nokogiri::XML(IO.read(path))

    # The magic.
    svg.css('script').each(&:remove)
    svg.css('image').reject { |x| x.attributes['href'].to_s =~ DATA_URI_REGEX }.each(&:remove)

    File.open(path, 'w') do |file|
      file.write svg.to_xml
    end
  rescue StandardError
    nil
  end
end
