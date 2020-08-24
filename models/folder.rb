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
      cfp = File.join(full_path, c)
      crp = File.join(path, c).gsub(/^\//, '')
      if File.directory?(cfp)
        sub = Folder.find_or_create_by(path: crp)
        dirs << sub
      else
        files << {t: c, sym: File.symlink?(cfp) ? true : false}
      end
    end
    return {dirs: dirs.sort{|a,b| a.path <=> b.path}, files: files.sort{|a,b| a[:t] <=> b[:t]}}
  end
end
