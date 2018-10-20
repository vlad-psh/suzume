class Release < ActiveRecord::Base
  belongs_to :performer
  has_many :records
  has_many :folders

  def full_path
    return nil unless self.directory
    return File.join($library_path, self.directory)
  end

  def download_cover
    return nil unless path = self.full_path

    %w(jpg png).each do |ext|
      return File.join('/rdownload', self.directory, "cover.#{ext}") if File.exist?(File.join(path, "cover.#{ext}"))
    end

    return nil
  end

  def download_thumb
    return nil unless path = self.full_path

    %w(jpg png).each do |ext|
      return File.join('/rdownload', self.directory, "thumb.#{ext}") if File.exist?(File.join(path, "thumb.#{ext}"))
    end

    return nil
  end

  def maybe_completed!
    if self.folders.map{|i| i.is_processed ? 0 : 1}.sum == 0
      self.update_attribute(:completed, true)
    end
  end
end