# frozen_string_literal: true

class Image::VoteMigration
  include ActiveModel::Model

  attr_accessor :target, :source

  validates :target, :source, presence: true

  def save
    return false unless valid?

    source.votes.find_each do |v|
      target.votes.create(user: v.user, image: target, up: v.up)
    end

    source.faves.find_each do |f|
      target.faves.create(user: f.user, image: target)
    end

    source.hides.find_each do |h|
      target.hides.create(user: h.user, image: target)
    end
  end
end
