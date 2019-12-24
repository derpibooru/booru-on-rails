# frozen_string_literal: true

module Booru
  module Uploads
    class FileAttachment
      # Attempt to save an attachment with configuration options
      # specified in the given model's class. Fails if the file
      # is considered invalid by the validator, or if the file
      # cannot be written.
      #
      # @param model [ApplicationRecord]
      #   a model instance
      # @param column [Symbol]
      #   the name of the column the assignment is intended for
      # @param file [File]
      #   the file to attempt to persist
      #
      # @return [String]
      #   the name of the file in the store directory. You should
      #   assign this to +column+ when the method returns.
      #
      def self.persist!(model:, column:, file:)
        # Build the format for this file.
        format = Mime.format_for(file.path)
        config = model.class.base_class.file_config[column]

        # Validate the file.
        validators = config.validators
        validators.each { |v| v.validate!(model: model, format: format) }
        raise ActiveRecord::RecordInvalid, model if model.errors.any?

        # Write related attributes about the file.
        writers = config.writers
        writers.each { |w| w.write!(model: model, format: format) }

        # Write the file to disk.
        name     = store_name(extension: format.extension)
        filename = "#{config.store_dir}/#{name}"
        dirname  = File.dirname(filename)

        Rails.logger.debug("Writing file #{filename}")
        FileUtils.mkdir_p(dirname)
        FileUtils.cp(file.path, filename)
        FileUtils.chmod(0o644, filename)

        name
      rescue KeyError
        # Convert to a validation error if the format was not found.
        model.errors.add(column, 'has unknown content type')
        raise ActiveRecord::RecordInvalid, model
      end

      # Remove an attachment from disk, if it exists.
      #
      # @param model [ApplicationRecord] a model instance
      # @param column [Symbol] the referenced column
      # @param value [String] the name of the file in its +store_dir+
      #
      def self.unpersist!(model:, column:, path:)
        config = model.class.base_class.file_config[column]
        FileUtils.rm("#{config.store_dir}/#{path}")
      rescue Errno::ENOENT
        Rails.logger.warn "Ignoring nonexistent file #{path}"
      end

      # Provide an underlying store name based off of the current PID, TID,
      # and time in nanoseconds. This is guaranteed to be unique with
      # concurrent instances.
      #
      # @param extension [String] the file extension to use
      # @return [String]
      #
      def self.store_name(extension:)
        time = Time.zone.now
        pid = Process.pid
        tid = Thread.current.object_id

        values = [
          time.year, '/', time.month, '/', time.day, '/',
          time.hour, time.min, time.sec, time.tv_usec,
          time.tv_nsec, pid, tid, '.', extension
        ]

        values.join('')
      end

      # Create a new FileAttachment. The referenced file should exist.
      #
      # @param model [ApplicationRecord] a model instance
      # @param column [Symbol] the referenced column
      # @param value [String] the name of the file in its +store_dir+
      #
      def initialize(model:, column:, path:)
        @model = model
        @column = column
        @config = model.class.base_class.file_config[column]
        @path = path
      end

      # Access a file object for this attachment.
      #
      # @return [File]
      #
      def file
        @file ||= File.open(file_path)
      end

      # Access the file path for this attachment.
      #
      # @return [String]
      #
      def file_path
        @file_path ||= "#{@config.store_dir}/#{@path}"
      end

      # Access the URL for this attachment.
      #
      # @return [String]
      #
      def url
        @url ||= "#{@config.url_prefix}/#{@path}"
      end
    end
  end
end
