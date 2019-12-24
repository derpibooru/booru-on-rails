# frozen_string_literal: true

class SiteNotice < ApplicationRecord
  belongs_to :user, optional: true
  validates :start_date, presence: { message: 'must be populated. (Try "now".)' }
  validates :finish_date, presence: { message: 'must be populated. (Try "a day from now".)' }

  resourcify

  def self.current
    SiteNotice.where(live: true).where('start_date <  ?', Time.zone.now).where('finish_date > ?', Time.zone.now).order(start_date: :desc)
  end

  def start=(sometime)
    self.start_date = Chronic.parse(sometime)
  end

  def start
    start_date.to_s
  end

  def finish=(sometime)
    self.finish_date = Chronic.parse(sometime)
  end

  def finish
    finish_date.to_s
  end
end
