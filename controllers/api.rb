paths api_tags: '/api/tags'

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

get :api_tags do

end
