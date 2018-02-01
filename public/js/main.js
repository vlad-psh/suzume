$(document).on('submit', '.add-tag-form', function(event){
  event.preventDefault();

  var serialized_form = $(this).serialize();
  var input_tag = $(this).find('.new-tag-input');
  var new_tag = input_tag.val().split(':');
  if (new_tag.length != 2) {
    alert("Please enter correct tag");
    return false;
  }

  input_tag.val('');

  $.ajax({
    url: "/tag/add",
    method: "POST",
    data: serialized_form
  }).done(function(data){
    input_tag.before(data);
  });
});

$(document).on('click', '.remove-tag-link', function(){
  var tag_id = $(this).data("tag-id");
  var obj_type = $(this).data("parent-type");
  var obj_id = $(this).data("parent-id");
  var this_parent = $(this).parent();

  $.ajax({
    url: "/tag/remove",
    method: "POST",
    data: {obj_type: obj_type, obj_id: obj_id, tag_id: tag_id}
  }).done(function(data){
    this_parent.remove();
  });
});

$(document).on('click', '.tags-block', function(){
  $(this).find('.new-tag-input').focus();
});

$(document).on('click', '.cmus-link', function(){
  var album_id = $(this).data("album-id");
  var url = $(this).data("url");

  $.ajax({
    url: url,
    method: "POST",
    data: {id: album_id}
  });
});

$(document).on('click', '.release-edit-button', function(){
  var id = $(this).data("release-id");
  $.ajax({
    url: $(this).data("url"),
    method: "GET"
  }).done(function(data){
    $("#release-line-" + id).html(data);
  });
});

$(document).on('click', '.release-cancel-button', function(){
  var id = $(this).data("release-id");
  $.ajax({
    url: $(this).data("url"),
    method: "GET"
  }).done(function(data){
    $("#release-line-" + id).html(data);
  });
});

$(document).on('click', '.release-save-button', function(){
  var id = $(this).data("release-id");
  var serialized_form = $(this).parent().serialize();
  $("#release-line-" + id + " input").prop("disabled", true);

  $.ajax({
    url: $(this).data("url"),
    method: "POST",
    data: serialized_form
  }).done(function(data){
    $("#release-line-" + id).html(data);
  });
});

$(document).on('mouseenter', '.release-line', function(){
  var textArea = $(this).find('.title-romaji');
  textArea.text(textArea.data("romaji"));
});

$(document).on('mouseleave', '.release-line', function(){
  var textArea = $(this).find('.title-romaji');
  textArea.text(textArea.data("title"));
});

// ***************************************
// RATINGS
// ***************************************

var ratingNames = ["Not Rated","Appalling","Horrible","Very Bad","Bad","Average","Fine","Good","Very Good","Great","Masterpiece"];

$(document).on('mousemove', 'div.rating', function(event){
  var rating = getRatingFromPosition($(this), event);
  updateRatingBlock($(this), rating);
});

$(document).on('mouseleave', 'div.rating', function(event){
  updateRatingBlock($(this), $(this).data('rating'));
});

$(document).on('click', 'div.rating', function(event){
  var el = $(this);
  var rating = getRatingFromPosition(el, event);
  $.ajax({
    url: el.data('url'),
    method: "POST",
    data: {rating: rating}
  }).done(function(data){
    el.data('rating', data);
    updateRatingBlock(el, data);
  });
});

function getRatingFromPosition(el, event){
  var offsetX = el.offset().left;
  var width = el.width();
  var rating = Math.round( (event.pageX - offsetX) / width * 10 );
  return rating;
}

function updateRatingBlock(el, rating){
  if (el.data('current-rating') != rating) {
    el.removeClass('rated-' + el.data('current-rating'));
    el.addClass('rated-' + rating);
    el.data('current-rating', rating);
    el.html(ratingNames[rating]);
  }
}

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
  var playlist = [];
  var playIndex = 0;
  var player = $('#main-player')[0];
  var progressUpdateInterval;

  function startUpdateProgress(){
    if (!progressUpdateInterval){
      progressUpdateInterval = setInterval(updateProgress, 500);
    }
  };

  function stopUpdateProgress(){
    if (progressUpdateInterval){
      clearInterval(progressUpdateInterval);
      progressUpdateInterval = undefined;
    }
  };

  function updateProgress(){
    var hPercent = (player.currentTime / player.duration * 100).toFixed(4);
    $('#progress-bar-current').css('width', hPercent + '%');
    //console.log(percent);
  };

  function progressBarPercents(event){
    var percent = (event.pageX - $('#progress-bar').offset().left) / $('#progress-bar').width();
    if (percent > 100){
      percent = 100;
    } else if (percent < 0){
      percent = 0;
    }
    return percent;
  };

  var seekProgressMove = function(event){
    $('#progress-bar-current').css('width', progressBarPercents(event) * 100 + '%');
    //console.log("mousemove: " + event.pageX);
  };

  var seekProgressMouseUp = function(event){
    event.preventDefault();
    //console.log("mouseup: " + event.screenX);

    $(document).off('mouseup', seekProgressMouseUp);
    $(document).off('mousemove', seekProgressMove);

    $('#progress-bar').removeClass('seeking');
    player.currentTime = progressBarPercents(event) * player.duration;

    startUpdateProgress();
  };

  $(document).on('mousedown', '#progress-bar', function(event){
    if (!player.paused){
      event.preventDefault();
      //console.log("mousedown: " + event.pageX);

      stopUpdateProgress();
      $('#progress-bar').addClass('seeking');
      $('#progress-bar-current').css('width', progressBarPercents(event) * 100 + '%');

      $(document).on('mouseup', '', seekProgressMouseUp);
      $(document).on('mousemove', seekProgressMove);
    }
  });

  $(document).on('click', '#pause-button', function(){
    if (player.paused){
      player.play();
      startUpdateProgress();
    } else {
      player.pause();
      stopUpdateProgress();
    }
  });

  $(document).on('click', '.toggle-link', function(){
    var target = $(this).data('target');
    $(target).toggle();
  });

  $(document).on('click', '.track-playback-link', function(event){
    event.preventDefault();

    var track_url = $(this).data('track-url');
    playlist = [];
    $('.track-playback-link').each(function(){
      var url = $(this).data('track-url');
      playlist.push(url);
      console.log(url);
      if (url == track_url) {
        playIndex = playlist.length - 1;
      }
    });

    play();
  });

  function play(){
    $(player).attr('src', playlist[playIndex]);
    player.play();
    startUpdateProgress();
    $('.track-now-playing').removeClass('track-now-playing');
    $('.track-playback-link').each(function(){
      if ($(this).data('track-url') == playlist[playIndex]) {
        $(this).addClass('track-now-playing')
      }
    });
  }

  $('#main-player').on('ended', function(){
    playIndex = playIndex + 1;
    if (playIndex < playlist.length) {
      player.currentTime = 0;
      play();
    } else {
      stopUpdateProgress();
    }
  });
});
