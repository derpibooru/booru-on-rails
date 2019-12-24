# frozen_string_literal: true

require 'has_array_field'
require 'has_tag_proxy'
require 'postgres_set'

# ActiveRecord extensions. Defined in a separate module to avoid
# being overridden by gems (CarrierWave in particular)
module ActiveRecordExtensions
  def reload(*)
    run_callbacks(:reload) { super }
  end
end

class ApplicationRecord < ActiveRecord::Base
  prepend ActiveRecordExtensions
  extend Booru::Uploads::ModelExtensions

  define_model_callbacks :reload, only: [:after]

  self.abstract_class = true
end
