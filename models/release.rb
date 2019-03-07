class Release < ActiveRecord::Base
  belongs_to :performer
  has_many :records
  has_many :folders

  def full_path
    return nil unless self.directory
    return File.join($library_path, self.directory)
  end

  def maybe_completed!
    if self.folders.map{|i| i.is_processed ? 0 : 1}.sum == 0
      self.update_attribute(:completed, true)
    end
  end
end
