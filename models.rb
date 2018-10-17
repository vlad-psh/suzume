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
end

class Record < ActiveRecord::Base
  belongs_to :release
  has_one :performer, through: :release
  has_and_belongs_to_many :playlists

  def filename
    uid + '.' + extension
  end

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
  belongs_to :release

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
      c_fullpath = File.join(self.full_path, c)

      if skip_folders.include?(c_path)
        skip_folders.delete(c_path)
        next
      end

      next unless File.directory?(c_fullpath)

      tulip_id_files = Dir.glob(File.join(c_fullpath, ".tulip.id.*"))
      if tulip_id_files.count > 0 # should be only one file; TODO: review this condition
        c_folder_ids = tulip_id_files.map{|i| i.sub(/.*\.tulip\.id\./, '').to_i}
        c_folders = Folder.where(id: c_folder_ids).order(id: :asc)

        tulip_id_files.each do |tulip_id_file|
          c_id = tulip_id_file.sub(/.*\.tulip\.id\./, '').to_i

          # We only need one .tulip.id.# file
          # We choose ID that was created earlier than others and has Folder object
          # Ideally there shouldn't be more than one .tulip.id.# files, but...
          next if c_folders[0].try(:id) == c_id

          # Delete all other .tulip.id.# files
          File.delete(tulip_id_files[0])
        end

        if (f = c_folders[0]).present?
          # update parents
          f.path = c_path
          f.folder_id = self.id
          f.parent_ids = [self.parent_ids, self.id].flatten
          f.is_removed = false
          f.is_symlink = File.symlink?(c_fullpath)
          f.save if f.changed?
        end

      else
        Folder.create(
            path: c_path,
            folder_id: self.id,
            parent_ids: [self.parent_ids, self.id].flatten,
            is_symlink: File.symlink?(c_fullpath)
        )
      end

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

      next unless File.exist?(c_fullpath) # broken symbolic links
      next if File.directory?(c_fullpath)
      next if c =~ /\.tulip\.id\./
      file_list.delete(c) if file_list.include?(c)

      self.files[md5] ||= {}
      self.files[md5]['fln']  ||= c
      self.files[md5]['size'] ||= File.size(c_fullpath)

      if c =~ /\.(mp3|m4a)$/i
        self.files[md5]['type'] ||= 'audio'
        self.files[md5]['rating'] ||= nil
        self.files[md5]['dur'] ||= mediainfo(c_fullpath).audio.duration
        self.files[md5]['br']  ||= mediainfo(c_fullpath).audio.bit_rate
        self.files[md5]['brm'] ||= mediainfo(c_fullpath).audio.bit_rate_mode
        self.files[md5]['sr']  ||= mediainfo(c_fullpath).audio.sample_rate
        self.files[md5]['ch']  ||= mediainfo(c_fullpath).audio.channels
        # mediainfo() method will be executed only if there is not enough information about audio
      elsif c=~ /\.(png|jpg|jpeg)$/i
        self.files[md5]['type'] ||= 'image'
      end
    end

    # Files, which were not found during current folder lookup
    file_list.each {|f| self.files.delete(md5_of_filename(f))}

    self.save if self.changed?

    tulip_id_filepath = File.join(self.full_path, ".tulip.id.#{self.id}")
    # Do not save .tulip.id in root folder (and do not save if already exists)
    FileUtils.touch(tulip_id_filepath) unless File.exist?(tulip_id_filepath) || self.folder_id == nil

    return self.files
  end

  def set_rating(md5, _rating)
    rating = _rating.to_i
    filename = self.files[md5].try(:[], 'fln')
    throw StandardError.new("Wrong file MD5: #{md5}") unless filename
    self.files[md5]['rating'] = rating

    self.save if self.changed?
  end

  def process!
    throw StandardError.new("Already processed") if self.is_processed
    release = self.release
    performer = release.performer

    self.files.each do |md5,details|
      if details['type'] == 'audio' && details['rating'].present? && details['rating'] >= 0
        FileUtils.mkdir_p(release.full_path) unless Dir.exist?(release.full_path)
        # create unique newfilename
        extension = details['fln'].downcase.gsub(/.*\.([^\.]*)/, "\\1")
        while File.exist?(File.join(release.full_path, newfilename = "#{SecureRandom.hex(4)}.#{extension}")) do end

        oldfilepath = File.join(self.full_path, details['fln'])
        newfilepath = File.join(release.full_path, newfilename)
        FileUtils.copy(oldfilepath, newfilepath)

        if extension == 'mp3'
          `id3 -2 -rAPIC -rGEOB -s 0 -R '#{newfilepath}'`
        elsif extension == 'm4a'
          `mp4art --remove '#{newfilepath}'`
          `mp4file --optimize '#{newfilepath}'`
        end

        record = Record.create(
          release: release,
          original_filename: details['fln'],
          filename: newfilename,
          directory: release.directory,
          rating: details['rating']
        )
        record.update_mediainfo!
      end
    end

    # Add/copy album cover image
    self.files.each do |md5,details|
      if details['type'] == 'image' && details.has_key?('cover') && details['cover'] == true
        FileUtils.mkdir_p(release.full_path) unless Dir.exist?(release.full_path)

        oldfilepath = File.join(self.full_path, details['fln'])
        extension = details['fln'].downcase.gsub(/.*\.([^\.]*)/, "\\1")
        newfilepath = File.join(release.full_path, "cover.#{extension}")
        thumbfilepath = File.join(release.full_path, "thumb.#{extension}")
        FileUtils.copy(oldfilepath, newfilepath)

        img = MiniMagick::Image.open(newfilepath)
        if [img.width, img.height].max > 400
          img.resize("400x400>")
          img.write(thumbfilepath)
        else
          FileUtils.copy(newfilepath, thumbfilepath)
        end
        img.destroy! # remove temp file
      end
    end if release.records.count > 0 && new_release == true # TODO: check if new_release

    self.update_attributes(is_processed: true)

    flash[:notice] = "Folder \"#{self.path}\" processed successfully"
  end
end
