get :api_index do
  result = {artists: [], albums: [], songs: []}
  Performer.all.order(title: :asc).each do |a|
    result[:artists] << {id: a.id, title: a.title}
  end
  return result.to_json
end

get :api_performer do
  performer = Performer.find(params[:id])
  halt(404, 'Not found') unless performer.present?
  return performer.api_json
end

