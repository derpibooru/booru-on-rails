# frozen_string_literal: true

module Booru
  module Uploads
    # Model extensions for ActiveRecord file storage support.
    #
    #   class ApplicationRecord < ActiveRecord::Base
    #     # ...
    #     extend Booru::Uploads::ModelExtensions
    #   end
    #
    module ModelExtensions
      # Define an uploaded file for this model. This defines
      # two new methods on instances of the class to access
      # the given upload.
      #
      # @param name [Symbol] the column name
      # @param options [Hash] any additional options
      # @see FileAttachment
      # @see FileConfig
      #
      # @example
      #
      #   class Advert < ApplicationRecord
      #     file :image,
      #       store_dir:  '/srv/images/adverts',
      #       url_prefix: '/adverts'
      #   end
      #
      def file(name, options)
        config = file_config[name]

        config.store_dir  = options[:store_dir]  || Booru::CONFIG.settings[:default_file_path]
        config.url_prefix = options[:url_prefix] || Booru::CONFIG.settings[:default_url_prefix]

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          # Attempt to validate and persist this file immediately.
          # Any installed validations will be run when the column is
          # assigned to. Validation or file write failure will add errors
          # at validation time.
          #
          # @param file [File]
          #   a File, including any and all derived classes like
          #   Rack::UploadedFile and Tempfile
          #
          def uploaded_#{name}=(file)                  # def uploaded_image=(file)
            return if file.blank?                      #   return if file.blank?
                                                       #
            removed_#{name}s << #{name}                #   removed_images << image
                                                       #
            self.#{name} = FileAttachment.persist!(    #   self.image = FileAttachment.persist!(
              model:  self,                            #     model:  self,
              column: :#{name},                        #     column: :image,
              file:   file                             #     file:   file
            )                                          #   )
                                                       #
            added_#{name}s << #{name}                  #   added_images << image
            @uploaded_#{name} = nil                    #   @uploaded_image = nil
            @#{name}_errors = nil                      #   @image_errors = nil
          rescue ActiveRecord::RecordInvalid           # rescue ActiveRecord::RecordInvalid
            @#{name}_errors = errors.dup               #   @image_errors = errors.dup
          end                                          # end

          # Return the associated {FileAttachment} for this model. This
          # method may raise if the associated file is not present.
          #
          # @return [FileAttachment]
          #
          def uploaded_#{name}                         # def uploaded_image
            @uploaded_#{name} ||= FileAttachment.new(  #   @uploaded_image ||= FileAttachment.new(
              model:  self,                            #     model:  self,
              column: :#{name},                        #     column: :image,
              path:  #{name}                           #     path:   image
            )                                          #   )
          end                                          # end

          # Remove the associated {FileAttachment} for this model.
          #
          # @param value [true,false] removes only if present
          #
          def remove_#{name}=(value)                   # def remove_image=(value)
            value =                                    #   value =
              ActiveModel::Type::Boolean.new.cast(     #     ActiveModel::Type::Boolean.new.cast(
                value                                  #       value
              )                                        #     )
            return if value.blank?                     #   return if value.blank?
                                                       #
            removed_#{name}s << #{name}                #   removed_images << image
            self.#{name} = nil                         #   self.image = nil
            @uploaded_#{name} = nil                    #   @uploaded_image = nil
            @#{name}_errors = nil                      #   @image_errors = nil
          end                                          # end

          # Helper for Rails forms.
          #
          # @return [false]
          #
          def remove_#{name}                           # def remove_image
            false                                      #   false
          end                                          # end

          # Transaction helper. Allows for safe attachment removal around model
          # persistence.
          #
          # @return [Array]
          #
          def removed_#{name}s                         # def removed_images
            @removed_#{name}s ||= []                   #   @removed_images ||= []
          end                                          # end

          # Transaction helper. Allows for safe attachment removal around model
          # persistence.
          #
          # @return [Array]
          #
          def added_#{name}s                           # def added_images
            @added_#{name}s ||= []                     #   @added_images ||= []
          end                                          # end

          # Transaction helper. Removes unreferenced attachments around model
          # persistence.
          #
          after_commit do                              # after_commit do
            removed_#{name}s.compact.each do |f|       #   removed_images.compact.each do |f|
              FileAttachment.unpersist!(               #     FileAttachment.unpersist!(
                model:  self,                          #       model:  self,
                column: :#{name},                      #       column: :image,
                path:   f                              #       path:   f
              )                                        #     )
            end                                        #   end
                                                       #
            removed_#{name}s.clear                     #   removed_images.clear
            added_#{name}s.clear                       #   added_images.clear
          end                                          # end

          # Transaction helper. Removes unreferenced attachments around model
          # persistence.
          #
          after_rollback do                            # after_rollback do
            added_#{name}s.compact.each do |f|         #   added_images.compact.each do |f|
              FileAttachment.unpersist!(               #     FileAttachment.unpersist!(
                model:  self,                          #       model:  self,
                column: :#{name},                      #       column: :image,
                path:   f                              #       path:   f
              )                                        #     )
            end                                        #   end
                                                       #
            self.#{name} = #{name}_in_database         #   self.image = image_in_database
            @uploaded_#{name} = nil                    #   @uploaded_image = nil
            removed_#{name}s.clear                     #   removed_images.clear
            added_#{name}s.clear                       #   added_images.clear
          end                                          # end

          # Validation helper. Rails clears validation errors when #valid?
          # is called, so we have to add them back here.
          #
          validate do                                  # validate do
            next if @#{name}_errors.nil?               #   next if @image_errors.nil?
                                                       #
            @#{name}_errors.messages.each do |c, m|    #   @image_errors.messages.each do |c, m|
              errors.add(c, m[0])                      #     errors.add(c, m[0])
            end                                        #   end
          end                                          # end
        RUBY
      end

      # Register validations for the given file. If the file does not
      # validate on assignment, it will not be written. Options are
      # passed to the named validator.
      #
      # @param name [Symbol] file name
      # @param options [Hash] any additional options
      # @see ImageValidator
      #
      # @example
      #
      #   class Advert < ApplicationRecord
      #     file :image
      #     file_validator :image,
      #       validator: :image_validator,
      #       width:     699..729,
      #       height:    79..91,
      #       size:      0..500.kilobytes,
      #       mime:      %w[image/png image/jpeg image/gif]
      #   end
      #
      def file_validator(name, options)
        file_config[name].validate!(name, options)
      end

      # Register attributes for the given file. If the file does not
      # validate on assignment, these will not be written. Options are
      # passed to the attribute writer.
      #
      # @param name [Symbol] file name
      # @param options [Hash] any additional options
      # @see ImageAttributeWriter
      #
      # @example
      #
      #   class Image < ApplicationRecord
      #     file :image
      #     file_attributes :image,
      #       writer: :image_attribute_writer,
      #       width:  :image_width,
      #       height: :image_height,
      #       size:   :image_size,
      #       mime:   :image_content_type,
      #       ext:    :image_format,
      #       name:   :image_name,
      #       sha512: :image_sha512_hash
      #   end
      #
      def file_attributes(name, options)
        file_config[name].writer!(name, options)
      end

      # Directly access the file configuration for a column.
      #
      # @return [Hash]
      #
      def file_config
        @file_config ||= Hash.new do |hash, key|
          hash[key] = FileConfig.new
        end
      end
    end
  end
end
