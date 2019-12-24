# frozen_string_literal: true

Booru::CONFIG.image_json_query = "images.id, #{Booru::CONFIG.image_json_query[:query].gsub('Booru::CONFIG.settings[:image_url_root]', Booru::CONFIG.settings[:image_url_root])}"
