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

$(document).on('click', '.play-link', function(){
  var album_id = $(this).attr("data-album-id");

  $.ajax({
    url: "/play",
    method: "POST",
    data: {id: album_id}
  });
});

$(document).on('click', '.release-edit-button', function(){
  var id = $(this).attr("data-release-id");
  $.ajax({
    url: $(this).attr("data-url"),
    method: "GET"
  }).done(function(data){
    $("#release-line-" + id).html(data);
  });
});

$(document).on('click', '.release-cancel-button', function(){
  var id = $(this).attr("data-release-id");
  $.ajax({
    url: $(this).attr("data-url"),
    method: "GET"
  }).done(function(data){
    $("#release-line-" + id).html(data);
  });
});

$(document).on('click', '.release-save-button', function(){
  var id = $(this).attr("data-release-id");
  var serialized_form = $(this).parent().serialize();
  $("#release-line-" + id + " input").prop("disabled", true);

  $.ajax({
    url: $(this).attr("data-url"),
    method: "POST",
    data: serialized_form
  }).done(function(data){
    $("#release-line-" + id).html(data);
  });
});

$(document).on('mouseenter', '.release-line', function(){
  var textArea = $(this).find('.title-romaji');
  textArea.text(textArea.attr("data-romaji"));
});

$(document).on('mouseleave', '.release-line', function(){
  var textArea = $(this).find('.title-romaji');
  textArea.text(textArea.attr("data-title"));
});

