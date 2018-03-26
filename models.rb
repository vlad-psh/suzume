class Tag < ActiveRecord::Base
  has_and_belongs_to_many :performers
end

class Performer < ActiveRecord::Base
  has_many :releases
  has_many :records, through: :releases
  has_and_belongs_to_many :tags

  def sorted_records
    result = {}
    rr = records.includes(:release)

    prev_release = nil
    rr.sort_by {|rec| "#{rec.release.year}#{rec.release.title}"}.each do |r|
      result[r.release] ||= []
      result[r.release] << r
    end

    return result
  end
end

class Release < ActiveRecord::Base
  belongs_to :performer
  has_many :records

  def full_path
    return nil unless self.directory
    path = File.join($library_path, self.directory)
    return File.exist?(path) ? path : nil
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
end

class Record < ActiveRecord::Base
  belongs_to :release
  has_one :performer, through: :release
  has_and_belongs_to_many :playlists

  def full_path
    File.join($library_path, directory, filename)
  end

  def download_path
    File.join('/rdownload', directory, filename)
  end

  def update_mediainfo
    return unless File.exist?(self.full_path)
    m = MediaInfoNative::MediaInfo.new()
    m.open_file(self.full_path)
    self.mediainfo = {
      dur: m.audio.duration,
      br:  m.audio.bit_rate,
      brm: m.audio.bit_rate_mode,
      sr:  m.audio.sample_rate,
      ch:  m.audio.channels
    }
    m.close
  end

  def update_mediainfo!
    self.update_mediainfo
    self.save
  end

  def delete_from_filesystem
    File.delete(full_path) if File.exist?(full_path)
    self.delete
  end
end

class Playlist < ActiveRecord::Base
  has_and_belongs_to_many :records
end

class Folder < ActiveRecord::Base
  def self.root
    return Folder.find_or_create_by(path: '', folder_id: nil)
  end

  def full_path
    return File.join($abyss_path, path)
  end

  def name
    File.basename(self.path)
  end

  def subfolders
    update_content! unless @_subfolders # update content and set @_subfolders

    return @_subfolders
  end

  def update_content!
    skip_folders = Folder.where(folder_id: self.id, is_removed: false).pluck(:path)

    Dir.children(self.full_path).each do |c|
      c_path = self.path == '' ? c : File.join(self.path, c)

      if skip_folders.include?(c_path)
        skip_folders.delete(c_path)
        next
      end

      next unless File.directory?( File.join(self.full_path, c) )

      tulip_id_files = Dir.glob(File.join(self.full_path, c, ".tulip.id.*"))
      if tulip_id_files.count == 1 # should be only one file
        c_id = tulip_id_files[0].gsub(/.*\.tulip\.id\.([0-9]*)/, '\1').to_i # get only numbers
        f = Folder.find_by(id: c_id)
        if f.present?
          # update parents
          f.path = c_path
          f.folder_id = self.id
          f.parent_ids = [self.parent_ids, self.id].flatten
          f.is_removed = false
          f.save if f.changed?
          next
        else
          File.delete(tulip_id_files[0]) unless f.present?
        end
      end

      Folder.create(
          path: c_path,
          folder_id: self.id,
          parent_ids: [self.parent_ids, self.id].flatten
      )
    end

    skip_folders.each do |c|
      Folder.find_by(folder_id: self.id, is_removed: false, path: c).try(:mark_as_removed)
    end

    @_subfolders = Folder.where(folder_id: self.id, is_removed: false).order(path: :asc)
  end

  def mark_as_removed
    Folder.where(folder_id: self.id, is_removed: false).each do |f|
      f.mark_as_removed
    end
    self.is_removed = true
    self.save
  end

  def mediainfo(fullpath)
    @mediainfo ||= {}

    unless @mediainfo[fullpath].present?
      m = MediaInfoNative::MediaInfo.new()
      m.open_file(fullpath)
      @mediainfo[fullpath] = m
    end

    return @mediainfo[fullpath]
  end

  def md5_of_filename(filename)
    @files_md5s ||= self.files.map{|md5,details| {details['fln'] => md5} }.reduce({}, :merge)
    return @files_md5s[filename]
  end

  def get_files!
    file_list = self.files.map {|md5,details| details['fln']}

    Dir.children(self.full_path).each do |c|
      md5 = Digest::MD5.hexdigest(c)[0..6] # first 7 chars (as in github)
      c_fullpath = File.join(self.full_path, c)

      next if File.directory?(c_fullpath)
      next if c =~ /\.tulip\.id\./
      file_list.delete(c) if file_list.include?(c)

      self.files[md5] ||= {}
      self.files[md5]['fln']  ||= c
      self.files[md5]['size'] ||= File.size(c_fullpath)

      if c =~ /\.(mp3|m4a)/i
        self.files[md5]['type'] ||= 'audio'
        self.files[md5]['rating'] ||= nil
        self.files[md5]['dur'] ||= mediainfo(c_fullpath).audio.duration
        self.files[md5]['br']  ||= mediainfo(c_fullpath).audio.bit_rate
        self.files[md5]['brm'] ||= mediainfo(c_fullpath).audio.bit_rate_mode
        self.files[md5]['sr']  ||= mediainfo(c_fullpath).audio.sample_rate
        self.files[md5]['ch']  ||= mediainfo(c_fullpath).audio.channels
        # mediainfo() method will be executed only if there is not enough information about audio
      elsif c=~ /\.(png|jpg|jpeg)/i
        self.files[md5]['type'] ||= 'image'
      end
    end

    # Files, which were not found during current folder lookup
    file_list.each {|f| self.files.delete(md5_of_filename(c))}

    self.save if self.changed?

    tulip_id_filepath = File.join(self.full_path, ".tulip.id.#{self.id}")
    FileUtils.touch(tulip_id_filepath) unless File.exist?(tulip_id_filepath)

    return self.files
  end
end
