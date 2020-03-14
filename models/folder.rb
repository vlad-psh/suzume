class Folder < ActiveRecord::Base
  belongs_to :release
  validates :nodes, presence: true # Prevents accidentally saving of 'virtual root'

  def self.root
    Folder.new(path: '', nodes: nil)
  end

  def is_root?
    nodes === nil ? true : false
  end

  def parent
    return nil if is_root?
    (parent_id = nodes.last) ? Folder.find(parent_id) : Folder.root
  end

  def parent=(p)
    self.nodes = p.is_root? ? [] : p.nodes + [p.id]
  end

  def full_path
    return File.join($abyss_path, path)
  end

  def name
    File.basename(self.path)
  end

  def subfolders
    Folder.where(nodes: (is_root? ? [] : nodes + [id]), is_removed: false).order(path: :asc)
  end

  def subfolders!
    return @_subfolders if @_subfolders

    skip_folders = subfolders.pluck(:path)

    Dir.children(self.full_path).each do |c|
      c_path = self.path == '' ? c : File.join(self.path, c)
      c_fullpath = File.join(self.full_path, c)

      if skip_folders.include?(c_path)
        skip_folders.delete(c_path)
        next
      end

      next unless File.directory?(c_fullpath)

      tulip_id_files = Dir.children(c_fullpath).select{|i| i =~ /\.tulip\.id\./}
      folder_obj_exists = false

      if tulip_id_files.count > 0 # should be only one file; TODO: review this condition
        c_folder_id = tulip_id_files[0].sub(/.*\.tulip\.id\./, '').to_i
        c_folder = Folder.find_by(id: c_folder_id)

        if (f = c_folder).present?
          # update parents
          f.path = c_path
          f.parent = self
          f.is_removed = false
          f.is_symlink = File.symlink?(c_fullpath)
          f.save if f.changed?
          folder_obj_exists = true
        else
          File.delete(File.join(c_fullpath, tulip_id_files.first))
        end
      end

      unless folder_obj_exists
        f = Folder.create(
            path: c_path,
            parent: self,
            is_symlink: File.symlink?(c_fullpath)
        )
        FileUtils.touch(File.join(c_fullpath, ".tulip.id.#{f.id}"))
      end

    end

    subfolders.where(path: skip_folders).each{|sf| sf.mark_as_removed}

    @_subfolders = subfolders
  end

  def mark_as_removed
    subfolders.each do |f|
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
    FileUtils.touch(tulip_id_filepath) unless File.exist?(tulip_id_filepath) || is_root?

    return self.files
  end

  def set_rating(md5, _rating)
    rating = _rating.to_i
    filename = self.files[md5].try(:[], 'fln')
    throw StandardError.new("Wrong file MD5: #{md5}") unless filename
    self.files[md5]['rating'] = rating

    self.save if self.changed?
  end

  def update_image(md5)
    details = self.files[md5]

    throw StandardError.new("File with MD5 #{md5} doesn't exist in folder #{self.id}") unless details.present?
    throw StandardError.new("File with MD5 #{md5} is not an image file") if details['type'] != 'image'

    return unless Dir.exist?(self.release.full_path)
    cover_names = Dir.children(self.release.full_path).select{|i| i =~ /cover\./}
    if cover_names.length > 0
      src_size = File.size( File.join(self.full_path, details['fln']) )
      # we can assume that there is only one 'cover.*' file
      dst_size = File.size( File.join(self.release.full_path, cover_names.first) )
      return if src_size == dst_size
    end

    # Delete old covers
    Dir.children(self.release.full_path).select{|i| i =~ /(cover|thumb)\./}.each do |imgname|
      File.delete( File.join(self.release.full_path, imgname) )
    end

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
    self.release.update_attribute(:cover, extension)
  end

  def create_audio_record(md5)
    details = self.files[md5]

    FileUtils.mkdir_p(self.release.full_path) unless Dir.exist?(self.release.full_path)
    extension = details['fln'].downcase.gsub(/.*\.([^\.]*)/, "\\1")
    # Select unique id for new filename
    while Record.where(uid: (uid = SecureRandom.hex(4))).present? do end

    oldfilepath = File.join(self.full_path, details['fln'])
    newfilepath = File.join(self.release.full_path, "#{uid}.#{extension}")
    FileUtils.copy(oldfilepath, newfilepath)

    if extension == 'mp3'
      `id3 -2 -rAPIC -rGEOB -s 0 -R '#{newfilepath}'`
    elsif extension == 'm4a'
      `mp4art --remove '#{newfilepath}'`
      `mp4file --optimize '#{newfilepath}'`
    end

    record = Record.create(
      release: self.release,
      original_filename: details['fln'],
      directory: self.release.directory,
      uid: uid,
      extension: extension,
      rating: details['rating']
    )

    record.update_mediainfo!

    self.files[md5]['uid'] = record.uid
    self.save
  end

  def update_audio(md5)
    details = self.files[md5]
    throw StandardError.new("File with MD5 #{md5} doesn't exist in folder #{self.id}") unless details.present?
    throw StandardError.new("File with MD5 #{md5} is not an audio file") if details['type'] != 'audio'

    if details['uid'].present?
      r = Record.find_by(uid: details['uid'])
      throw StandardError.new("Record not found by uid = #{details['uid']}") unless r.present?
      if details['rating'].present? && details['rating'] >= 0
        r.update_attribute(:rating, details['rating'])
      else
        r.delete_from_filesystem
        self.files[md5].delete('uid')
      end
    else
      if details['rating'].present? && details['rating'] >= 0
        create_audio_record(md5)
      # else # nothing to do
      end
    end
    self.save
  end

  def process_files!
    throw StandardError.new("Already processed") if self.is_processed
    throw StandardError.new("Cannot process Folder without linked Release") if self.release.blank?

    self.files.each do |md5,details|
      next unless details['type'] == 'audio'
      update_audio(md5)
    end

    cover_index = self.files.keys.index {|i| self.files[i]['type'] == 'image' && self.files[i]['cover'] == true}
    update_image(self.files.keys[cover_index]) if cover_index.present?

    self.save if self.changed?
  end

  def full_process!
    process_files!
    self.is_processed = true
    self.save
    self.release.maybe_completed!
  end
end
