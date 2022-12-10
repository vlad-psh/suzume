class Folder < ActiveRecord::Base
  belongs_to :release

  def self.root
    Folder.new(path: '')
  end

  def full_path
    return File.join($abyss_path, path)
  end

  def name
    File.basename(self.path)
  end

  def parents
    parents = []

    while true
      parent_path = File.dirname(parent_path || path)
      break if parent_path == "." || parent_path == "/"
      parents << parent_path
    end

    Folder.where(path: parents).order(path: :asc)
  end

  def contents
    dirs = []
    files = []
    Dir.children(full_path).map do |c|
      cfp = File.join(full_path, c) # children full path
      crp = path == '' ? c : File.join(path, c) # children relative path
      if File.directory?(cfp)
        sub = Folder.find_or_create_by(path: crp)
        dirs << sub
      else
        files << {t: c, sym: File.symlink?(cfp) ? true : false}
      end
    end
    return {dirs: dirs.sort{|a,b| a.path <=> b.path}, files: files.sort{|a,b| a[:t] <=> b[:t]}}
  end

  def link_to_release!(release)
    Dir.children(full_path).map do |f|
      f_fullpath = File.join(full_path, f)
      next if File.directory?(f_fullpath)
      next if f !~ /\.(mp3|m4a)$/

      track = Track.find_by(release_id: release.id, original_filename: f)
      if !track.present?
        track = Track.create(release: release, original_filename: f, folder: self)
        track.update_mediainfo!
      end
    end

    self.update(release_id: release.id)
    FileUtils.touch(File.join(full_path, ".tulip.id.#{id}"))
  end

  def contains_file?(filename)
    return false unless contents[:files].any? { |file| file[:t] == filename }

    File.exist?(File.join(full_path, filename))
  end
end
