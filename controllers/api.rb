paths \
  api_index: '/api/index',
  api_performer: '/api/performer/:id',
  api_abyss: '/api/abyss/:id',
  api_rating: '/api/rating/:uid',
  api_tags: '/api/tags'

get :api_index do
  protect!
  return Performer.all.order(title: :asc).map do |a|
    {
      id: a.id,
      title: a.romaji.present? ? "#{a.title} (#{a.romaji})" : a.title,
      aliases: a.aliases,
      tags: a.tags.pluck(:title)
    }
  end.to_json
end

get :api_performer do
  protect!
  performer = Performer.find(params[:id])
  halt(404, 'Not found') unless performer.present?
  return performer.api_json
end

get :api_abyss do
  protect!
  folder = Folder.eager_load(release: :performer).find_by(id: params[:id]) || Folder.root
  contents = folder.contents

  return folder.serializable_hash.merge({
    release: folder.release ? [folder.release.id, folder.release.title] : nil,
    performer: folder.release ? [folder.release.performer.id, folder.release.performer.title] : nil,
    files: contents[:files],
    name: (folder.is_symlink ? '🔗' : '') + folder.name,
    parents: folder.parents.map{|i| [i.id, (folder.is_symlink ? '🔗' : '') + File.basename(i.path)]},
    subfolders: contents[:dirs].map{|f|
      [f.id,
      (f.is_symlink ? '🔗' : '') + f.path,
       f.release ? [f.release.performer_id, f.release.performer.title] : nil
      ]
    },
  }).to_json
end

get :api_tags do

end

patch :api_rating do
  record = Record.find_by(uid: params[:uid])
  halt(404, 'Not found') unless record.present?
  record.update(rating: params[:rating])
  return record.rating.to_s
end
