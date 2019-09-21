get :api_index do
  return Performer.all.order(title: :asc).map do |a|
    {id: a.id, title: a.romaji.present? ? "#{a.title} (#{a.romaji})" : a.title}
  end.to_json
end

get :api_performer do
  performer = Performer.find(params[:id])
  halt(404, 'Not found') unless performer.present?
  return performer.api_json
end

