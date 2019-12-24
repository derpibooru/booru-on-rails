# frozen_string_literal: true

module Booru
  module Uploads
    class FileConfig
      # Mapping of known validators.
      VALIDATORS = {
        image_validator: ImageValidator
      }.freeze

      # Mapping of known attribute writers.
      WRITERS = {
        image_attribute_writer: ImageAttributeWriter
      }.freeze

      # Base directory at which a given file may be found.
      # @return [String]
      attr_accessor :store_dir

      # Scheme, domain, and path prepended to a URL before serving.
      # @return [String]
      attr_accessor :url_prefix

      # Installed validators for this file.
      # @return [Array<Validator>]
      def validators
        @validators ||= []
      end

      # Install a new validator for this file.
      # Currently only :image_validator is supported.
      def validate!(name, options)
        validators.push(VALIDATORS[options[:validator]].new(name, options))
      end

      # Installed attribute writers for this file.
      # @return [Array<AttributeWriter>]
      def writers
        @writers ||= []
      end

      # Install a new attribute writer for this file.
      # Currently only :image_attribute_writer is supported.
      def writer!(name, options)
        writers.push(WRITERS[options[:writer]].new(name, options))
      end
    end
  end
end
