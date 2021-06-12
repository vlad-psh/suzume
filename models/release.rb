class Release < ActiveRecord::Base
  self.primary_key = "id"
  belongs_to :artist
  has_many :tracks
  has_many :folders

  before_create :assign_id, if: -> {id.blank?}

  def full_path
    return File.join($library_path, id[0..1], id[2..])
  end

  def maybe_completed!
    if self.folders.map{|i| i.is_processed ? 0 : 1}.sum == 0
      self.update_attribute(:completed, true)
    end
  end

  def api_hash
    return {
      id: id,
      title: title,
      year: year,
      cover: cover,
      folders: folders.pluck(:id),
      tracks: tracks.map{|r| r.api_hash}
    }
  end

  def api_json
    return api_hash.to_json
  end

  private
  def assign_id
    while Release.where(id: (_id = SecureRandom.hex(4))).present? do end
    self.id = _id
  end
end
