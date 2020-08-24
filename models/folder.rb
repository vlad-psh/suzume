class Folder < ActiveRecord::Base
  belongs_to :release
  validates :nodes, exclusion: {in: [nil]} # Prevents accidentally saving of 'virtual root'

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

  def contents
    dirs = []
    files = []
    Dir.children(full_path).map do |c|
      cfp = File.join(full_path, c)
      crp = File.join(path, c).gsub(/^\//, '')
      result = {t: c}
      result[:sym] = true if File.symlink?(cfp)
      if File.directory?(cfp)
        sub = Folder.find_or_create_by(path: crp)
        result[:id] = sub.id
        dirs << result
      else
        files << result
      end
    end
    return {dirs: dirs.sort{|a,b| a[:t] <=> b[:t]}, files: files.sort{|a,b| a[:t] <=> b[:t]}}
  end
end
