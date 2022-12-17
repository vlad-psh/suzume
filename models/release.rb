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
      tracks: tracks.sort.map{|r| r.api_hash}
    }
  end

  def api_json
    return api_hash.to_json
  end

  def abyss_images
    folders.map do |folder|
      folder.contents[:files].filter do |file|
        file[:t] =~ /\.(png|jpg|jpeg)$/
      end.map do |file|
        {
          folder_id: folder.id,
          filename: file[:t],
          filesize: "#{ File.size(File.join(folder.full_path, file[:t])) / 1024 } KB",
        }
      end
    end.flatten
  end

  def set_cover!(src_full_path)
    # Delete old covers
    Dir.children(full_path).select{|i| i =~ /(cover|thumb)\./}.each do |imgname|
      File.delete( File.join(full_path, imgname) )
    end if Dir.exist?(full_path)

    extension = File.extname(src_full_path).gsub(/^\./, '')
    store_file(src_full_path, "cover.#{extension}")

    img = MiniMagick::Image.open(src_full_path)
    if [img.width, img.height].max > 400
      img.resize("400x400>")
      img.write(File.join(full_path, "thumb.#{extension}"))
    else
      store_file(src_full_path, "thumb.#{extension}")
    end
    img.destroy! # remove temp file

    self.update(cover: extension)
  end

  def store_file(src_full_path, dst_file_name)
    FileUtils.mkdir_p(full_path) unless Dir.exist?(full_path)
    FileUtils.cp(src_full_path, File.join(full_path, dst_file_name))
  end

  def groom!
    tracks.each(&:groom!)
  end

  private
  def assign_id
    while Release.where(id: (_id = SecureRandom.hex(4))).present? do end
    self.id = _id
  end
end
