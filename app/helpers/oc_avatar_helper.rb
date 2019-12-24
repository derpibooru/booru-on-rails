# frozen_string_literal: true

module OcAvatarHelper
  def oc_avatar_generator(displayedname)
    # Define a seed and create the generator
    input_seed = Zlib.crc32(displayedname)
    generator = Random.new(input_seed)

    # Set the ranges for the colors we are going to make
    color_range = 128
    color_brightness = 96

    # What species will this be?
    species = Booru::CONFIG.avatar[:species][generator.rand(0...Booru::CONFIG.avatar[:species].size)]

    # Create a bounded hex color string:
    # Body color
    color_bd = format('%.2x%.2x%.2x', generator.rand(color_range) + color_brightness, generator.rand(color_range) + color_brightness, generator.rand(color_range) + color_brightness)
    # Hair color
    color_mn = format('%.2x%.2x%.2x', generator.rand(color_range) + color_brightness, generator.rand(color_range) + color_brightness, generator.rand(color_range) + color_brightness)
    # Hair styles
    styles = Booru::CONFIG.avatar[:hair_shapes].select { |s| s[:species].include?(species) }
    style_mn = generator.rand(0...styles.size)

    # Make a charcater
    oc_avatar_svg(color_bd, color_mn, species, style_mn).html_safe
  end

  def oc_avatar_svg(color_bd, color_mn, species, style_mn)
    output = []

    output << Booru::CONFIG.avatar[:header]
    output << Booru::CONFIG.avatar[:background]
    output << Booru::CONFIG.avatar[:tail_shapes].select { |s| s[:species].include?(species) }.first[:shape].gsub('HAIR_FILL', color_mn)
    output << Booru::CONFIG.avatar[:body_shapes].select { |s| s[:species].include?(species) }.first[:shape].gsub('BODY_FILL', color_bd)
    output << Booru::CONFIG.avatar[:hair_shapes].select { |s| s[:species].include?(species) }[style_mn][:shape].gsub('HAIR_FILL', color_mn)
    output << Booru::CONFIG.avatar[:extra_shapes].select { |s| s[:species].include?(species) }.map { |s| s[:shape].gsub('BODY_FILL', color_bd) }.join('')
    output << Booru::CONFIG.avatar[:footer]

    output.join('')
  end
end
