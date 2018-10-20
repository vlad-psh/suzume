get :tags do
  protect!

  @tags = Tag.all.order(category: :asc, title: :asc)

  slim :tags, locals: {tags: @tags}
end

get :search_by_tag do
  protect!

  tag = Tag.find(params[:id].to_i)

  unless tag
    flash[:error] = "Tag with ID=#{params[:id]} was not found"
    redirect_to :index
  end

  @artists = tag.artists
  @sorted_albums = albums_by_type(tag.albums.order(year: :desc))
  @tracks = tag.tracks
  @notes = {}
  Note.where(parent_type: 't', parent_id: @tracks).each do |n|
    @notes[n.parent_id] ||= []
    @notes[n.parent_id] << n
  end

  slim :index
end

delete :tag do
  protect!

  tag = Tag.find(params[:id])
  unless tag
    flash[:error] = "Tag not found"
  else
    tag_title = tag.title
    _artists = tag.artists.count
    _albums = tag.albums.count
    _tracks = tag.tracks.count
    unless _artists == 0 && _albums == 0 && _tracks == 0
     flash[:error] = "Tag '#{tag_title}' still has childs. Artists: #{_artists}, albums: #{_albums}, tracks: #{_tracks}"
    else
      tag.destroy
      flash[:notice] = "Tag '#{tag_title}' successfully deleted"
    end
  end

  redirect path_to(:tags)
end

post :tag_add do
  protect!

  performer = Performer.includes(:tags).find(params[:performer_id])

  tag_category, tag_title = params[:tag_name].downcase.split(":")
  unless tag_category.length != 1
    tag = Tag.find_or_create_by(title: tag_title, category: tag_category)
    performer.tags << tag unless performer.tags.include?(tag)
  else
    halt 400, "Specify category!"
  end

  slim :tag_item, layout: false, locals: {tag: tag, performer: performer}
end

post :tag_remove do
  protect!

  TagRelation.where(
        parent_type: params[:obj_type],
        parent_id: params[:obj_id],
        tag_id: params[:tag_id]).each do |tr|
    tr.delete
  end

  return "OK"
end

