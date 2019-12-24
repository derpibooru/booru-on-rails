# frozen_string_literal: true

class Image::Feature < ApplicationRecord
  belongs_to :image
  belongs_to :user
end
