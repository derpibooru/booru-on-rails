# frozen_string_literal: true

require 'yaml'

module Booru
  # Helper class to load auxiliary YAML
  # configuration files.
  class ConfigLoader
    # Loads a new configuration object.
    #
    # @return [OpenStruct]
    def self.booru_config
      config     = OpenStruct.new
      file_paths = Rails.root.join('config', 'booru', '*.yml')

      Dir[file_paths].each do |filename|
        parsed   = YAML.load_file(filename)
        basename = File.basename(filename, '.yml')

        config[basename] = parsed
      end

      config
    end
  end

  # A global configuration object that contains items such as
  # predefined object mappings. To add a new element, simply
  # create a new YAML file in config/booru.
  #
  # For example, if config/booru/test.yml contains
  #   :hello_world:
  #     - hello
  #     - world
  # then the resulting Hash will be accessible at Booru::CONFIG.test,
  # and will be the following:
  #   { :hello_world => ["hello", "world"] }
  # .
  CONFIG = ConfigLoader.booru_config
end
