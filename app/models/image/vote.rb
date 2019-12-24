# frozen_string_literal: true

class Image::Vote < ApplicationRecord
  self.primary_keys = :image_id, :user_id

  belongs_to :image
  belongs_to :user

  after_create do
    user.inc_stat(:votes_cast)
  end

  after_destroy do
    user.dec_stat(:votes_cast)
  end

  # Ghetto counter cache
  before_save do
    image.with_lock do
      chg_upvotes    = -image.votes.where(user: user, up: true).delete_all
      chg_upvotes   += 1 if up
      chg_downvotes  = -image.votes.where(user: user, up: false).delete_all
      chg_downvotes += 1 if !up

      image.update_columns(
        score:           image.score + chg_upvotes - chg_downvotes,
        upvotes_count:   image.upvotes_count + chg_upvotes,
        downvotes_count: image.downvotes_count + chg_downvotes,
        updated_at:      Time.zone.now
      )
    end
  end

  before_destroy do
    image.with_lock do
      chg_upvotes   = 0
      chg_upvotes   = -1 if up
      chg_downvotes = 0
      chg_downvotes = -1 if !up

      image.update_columns(
        score:           image.score + chg_upvotes - chg_downvotes,
        upvotes_count:   image.upvotes_count + chg_upvotes,
        downvotes_count: image.downvotes_count + chg_downvotes,
        updated_at:      Time.zone.now
      )
    end
  end
end
