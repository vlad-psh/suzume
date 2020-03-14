paths \
  api_index: '/api/index',
  api_performer: '/api/performer/:id',
  api_abyss: '/api/abyss/:id',
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
  folder = Folder.find_by(id: params[:id]) || Folder.root

  return folder.serializable_hash.merge({
    name: (folder.is_symlink ? '🔗' : '') + folder.name,
    parents: Folder.where(id: folder.nodes).map{|f| [f.id, (f.is_symlink ? '🔗' : '') + File.basename(f.path)]},
    subfolders: folder.subfolders.pluck(:id, :path).map{|i,p| [i, File.basename(p)]},
  }).to_json
end

get :api_tags do

end
