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
    return Folder.find_or_create_by(path: '', parent_ids: [])
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
    skip_folders = Folder.where(folder_id: self.id).pluck(:path).map {|p| File.basename(p)}

    Dir.children(self.full_path).each do |c|
      if skip_folders.include?(c)
        skip_folders.delete(c)
        next
      end

      next unless File.directory?( File.join(self.full_path, c) )

      f = Folder.create(
          path: self.path == '' ? c : File.join(self.path, c),
          folder_id: self.id,
          parent_ids: [self.parent_ids, self.id].flatten
      )
    end

    # TODO: remove Folder objects, that are still in skip_folders array; RECURSIVELY!

    @_subfolders = Folder.where(folder_id: self.id).order(path: :asc)
  end

  def tulip_yml_path
    File.join(self.full_path, 'tulip.yml')
  end

  def tulip_yml
    return @_tulip_yml || self.get_tulip_yml
  end

  def get_tulip_yml
    @_tulip_yml = File.exist?(self.tulip_yml_path) ?
                    YAML.load(File.open(self.tulip_yml_path)) :
                    {notes: [], files: {}}
    return @_tulip_yml
  end

  def save_tulip_yml!
    return unless tulip_yml.present?

    File.open(self.tulip_yml_path, 'w') do |f|
      f.write(tulip_yml.to_yaml)
    end
  end

  def get_files
    files = tulip_yml[:files].map {|path,details| path}

    Dir.children(self.full_path).each do |c|
      c_fullpath = File.join(self.full_path, c)
      next if File.directory?(c_fullpath)
      next if c =~ /.*tulip\.yml$/

      if files.include?(c)
        files.delete(c)
        next
      end

      if c =~ /\.(mp3|m4a)/i
        m = MediaInfoNative::MediaInfo.new()
        m.open_file(c_fullpath)
        info = {
          type: 'audio',
          rating: nil,
          dur: m.audio.duration,
          br:  m.audio.bit_rate,
          brm: m.audio.bit_rate_mode,
          sr:  m.audio.sample_rate,
          ch:  m.audio.channels
        }
      elsif c=~ /\.(png|jpg|jpeg)/i
        info = {
          type: 'image'
        }
      end
      info ||= {}
      info[:size] = File.size(c_fullpath)

      tulip_yml[:files][c] = info
    end

    self.save_tulip_yml!
  end
end
