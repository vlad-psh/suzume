get :tags do
  protect!

  @tags = Tag.all.order(category: :asc, title: :asc)

  slim :tags, locals: {tags: @tags}
end

get :search_by_tag do
  protect!

  tag = Tag.find(params[:id])

  unless tag
    flash[:error] = "Tag with ID=#{params[:id]} was not found"
    redirect_to :index
  end

  @performers = tag.performers

  slim :performers
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
  tag = Tag.find_or_create_by(title: params[:tag_name])
  performer.tags << tag

  slim :tag_item, layout: false, locals: {tag: tag, performer: performer}
end

post :tag_remove do
  protect!

  performer = Performer.includes(:tags).find(params[:performer_id])
  tag = Tag.find(params[:tag_id])
  performer.tags.delete(tag)

  return "OK"
end

