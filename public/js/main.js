$(document).on('click', '.artist-remove-tag-link', function(){
  var tag_id = $(this).attr("data-tag-id");
  var artist_id = $(this).attr("data-artist-id");
  var this_parent = $(this).parent();

  $.ajax({
    url: "/artist/tag/remove",
    method: "POST",
    data: {artist_id: artist_id, tag_id: tag_id}
  }).done(function(data){
    this_parent.remove();
  });
});

$(document).on('click', '.album-remove-tag-link', function(){
  var tag_id = $(this).attr("data-tag-id");
  var album_id = $(this).attr("data-album-id");
  var this_parent = $(this).parent();
 
  $.ajax({
    url: "/album/tag/remove",
    method: "POST",
    data: {album_id: album_id, tag_id: tag_id}
  }).done(function(data){
    this_parent.remove();
  });
});

$(document).on('click', '.tags-block', function(){
  $(this).find('.new-tag-input').focus();
});
