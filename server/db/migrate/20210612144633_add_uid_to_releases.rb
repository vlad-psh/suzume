class AddUidToReleases < ActiveRecord::Migration[6.1]
  def up
    add_column :releases, :uid, :string
    add_column :tracks, :release_uid, :string
    add_column :folders, :release_uid, :string

    say_with_time "Generating new UIDs for releases" do
      Release.find_each do |r|
        while Release.where(uid: (_uid = SecureRandom.hex(4))).present? do end
        r.update(uid: _uid)
      end
    end

    id2uid = Hash[*Release.all.pluck(:id, :uid).flatten]

    say_with_time "Update relations to release table" do
      id2uid.each do |id,uid|
        Track.where(release_id: id).update_all(release_uid: uid)
        Folder.where(release_id: id).update_all(release_uid: uid)
      end
    end
  end
end
