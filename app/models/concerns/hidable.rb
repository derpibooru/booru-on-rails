# frozen_string_literal: true

# Concern for "soft-deleting" objects, i.e., hiding them from common user
# access. Methods are provided for setting certain fields that are expected
# on the model table. Those fields are:
#  * +hidden_from_users+, a boolean
#  * +deleted_by+, a foreign key to a +User+ object
#  * +deletion_reason+, a string that is expected for deleted objects
module Hidable
  extend ActiveSupport::Concern
  include ActiveSupport::Callbacks

  included do
    belongs_to :deleted_by, class_name: 'User', optional: true
    delegate :name, to: :deleted_by, prefix: true, allow_nil: true
    validates :deletion_reason, presence: { message: 'must be provided.', if: :hidden_from_users }
    validates :deletion_reason, length: { minimum: 2, maximum: 5000, allow_blank: true }
  end
end
