window.Vue = require('vue');
require("jquery-ui/ui/widgets/autocomplete.js");
require("jquery-ujs");

require('./vue-browser.js');
require('./vue-performer.js');

$(document).on('submit', '.add-tag-form', function(event){
  event.preventDefault();

  var input_tag = $(this).find('.new-tag-input');

  $.ajax({
    url: "/tag/add",
    method: "POST",
    data: $(this).serialize()
  }).done(function(data){
    input_tag.val('');
    input_tag.before(data);
  });
});

$(document).on('click', '.remove-tag-link', function(){
  var tag_id = $(this).data("tag-id");
  var performer_id = $(this).data("performer-id");
  var this_parent = $(this).parent();

  $.ajax({
    url: "/tag/remove",
    method: "POST",
    data: {tag_id: tag_id, performer_id: performer_id}
  }).done(function(data){
    this_parent.remove();
  });
});

$(document).on('click', '.tags-block', function(){
  $(this).find('.new-tag-input').focus();
});

// ***************************************
// RATINGS
// ***************************************

$(document).on('click', '.rating-choose-button', function(event){
  var p = $(this).offset();
  var tip = $('#title-tip');

  tip.data('url', $(this).data('url'));
  tip.show();

  var pleft = p.left + $(this).outerWidth()/2 - tip.outerWidth()/2;
  var ptop = p.top - tip.outerHeight() - 8;
  tip.attr("style", "left: " + pleft + "px; top: " + ptop + "px");

  event.stopPropagation();
});

$(document).on('click', '.rating-set-button', function(event){
  var rating = $(this).data('value');
  var url = $('#title-tip').data('url');

  $.ajax({
    url: url,
    method: "PATCH",
    data: {rating: rating}
  }).done(function(_data){
    var data = JSON.parse(_data);
    $("[data-url='" + url + "']").html(data.emoji);
    $('#title-tip').hide();
  });

  event.stopPropagation();
});

$(document).on('click', null, function(event){
  if ($('#title-tip').is(":visible")) {
    $('#title-tip').hide();
    event.stopPropagation();
  }
});

// ***************************************
// HIDE NOTES
// ***************************************

$(document).on('click', '.hide-notes-checkbox', function(e){
  $.ajax({
    method: "POST",
    url: "/notes/hide",
    data: {"hide-notes": this.checked}
  });
  if (this.checked) {
    $('body').addClass("hide-notes");
  } else {
    $('body').removeClass("hide-notes");
  };
});

// ***************************************
// AJAX INSERT FORMS (NOTES/LYRICS)
// ***************************************

$(document).on('ajax:beforeSend','.ajax-insert-form', function(xhr, settings){
  $(this).find('input, textarea').attr('disabled', true);
  return true;
});

$(document).on('ajax:success','.ajax-insert-form', function(xhr, data, status){
  var e = $(this).data('append-to');
  $(this).find('.clear-value').val('');
  $(this).find('input, textarea').attr('disabled', false);
  if ( $(this).parent().hasClass('hide-after-submit') ) {
    $(this).parent().hide();
  }
  $(e).append(data);
  $(e).show();
});

// ***************************************
// FULLSCREEN COVER
// ***************************************

$(document).on('click', '.cover-link', function(event){
  event.preventDefault();
  var link = $(this).attr('href');
  $('#fullscreen-cover-container img').attr('src', link);
  $('#fullscreen-cover-container').show();
});

$(document).on('click', '#fullscreen-cover-container', function(){
  $(this).hide();
  $('#fullscreen-cover-container img').attr('src', '');
});

// ***************************************
// AUDIO PLAYER
// ***************************************

$(document).ready(function(){
  var player = $('#main-player')[0];

  $(document).on('click', '.track-playback-link', function(event){
    event.preventDefault();

    var trackUrl = $(this).data('track-url');
    $(player).attr('src', trackUrl);
    player.play();
    $('.track-now-playing').removeClass('track-now-playing');
    $(this).addClass('track-now-playing');
  });
});
