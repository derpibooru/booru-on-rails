# frozen_string_literal: true

class ImageQuery
  def self.duplicates(intensities, dist = 0.25)
    Image.joins(:intensity).where(
      '(nw BETWEEN ? AND ?) AND ' \
      '(ne BETWEEN ? AND ?) AND ' \
      '(sw BETWEEN ? AND ?) AND ' \
      '(se BETWEEN ? AND ?)',
      intensities[:nw] - dist, intensities[:nw] + dist,
      intensities[:ne] - dist, intensities[:ne] + dist,
      intensities[:sw] - dist, intensities[:sw] + dist,
      intensities[:se] - dist, intensities[:se] + dist
    ).limit(20)
  end

  def self.interactions(image_ids, user_id)
    interactions = [
      Image::Vote.where(image_id: image_ids).where(user_id: user_id, up: true).select("image_id, user_id, 'voted' as interaction_type, 'up' as value").to_sql,
      Image::Vote.where(image_id: image_ids).where(user_id: user_id, up: false).select("image_id, user_id, 'voted' as interaction_type, 'down' as value").to_sql,
      Image::Fave.where(image_id: image_ids).where(user_id: user_id).select("image_id, user_id, 'faved' as interaction_type, null as value").to_sql,
      Image::Hide.where(image_id: image_ids).where(user_id: user_id).select("image_id, user_id, 'hidden' as interaction_type, null as value").to_sql
    ]

    Image::Vote.find_by_sql(interactions.join(' UNION ALL '))
  end
end
