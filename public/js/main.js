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
  var playlist = [];
  var playIndex = 0;
  var player = $('#main-player')[0];
  var progressUpdateInterval;
  var progressUpdateIntervalValue = null;
  $('#volumebar .slider-value').css('width', player.volume * 100 + '%');

  function startUpdateProgress(){
    if (!progressUpdateInterval){
      // 500ms is default value; it will be changed in updateProgress() function
      progressUpdateInterval = setInterval(updateProgress, 500);
      updateProgress(); // execute function immediately
    }
  };

  function stopUpdateProgress(){
    if (progressUpdateInterval){
      clearInterval(progressUpdateInterval);
      progressUpdateInterval = undefined;
      progressUpdateIntervalValue = null;
    }
  };

  function updateProgress(){
    var width = 0;

    if (progressUpdateIntervalValue == null) {
      if (player.duration) {
        progressUpdateIntervalValue = (player.duration / $('#progressbar').width() * 1000).toFixed(0)
        console.log("interval: " + progressUpdateIntervalValue);
        // recreate interval(timer) with correct interval value
        clearInterval(progressUpdateInterval);
        progressUpdateInterval = setInterval(updateProgress, progressUpdateIntervalValue);
      }
    }

    if (player.duration) {
      var hPercent = (player.currentTime / player.duration).toFixed(4);
      width = ($('#progressbar').width() * hPercent).toFixed(0);
    }
    $('#progressbar .slider-value').css('width', width + 'px');
    //console.log('width: ' + width);
  };

  function offsetPercents(el, event){
    var percent = (event.pageX - el.offset().left) / el.width();
    if (percent > 1){
      percent = 1;
    } else if (percent < 0){
      percent = 0;
    }
    return percent;
  };

// progressbar seeking

  var seekProgressMove = function(event){
    $('#progressbar .slider-value').css('width', offsetPercents($('#progressbar'), event) * 100 + '%');
    
  };

  var seekProgressMouseUp = function(event){
    event.preventDefault();

    $(document).off('mouseup', seekProgressMouseUp);
    $(document).off('mousemove', seekProgressMove);

    $('#progressbar').removeClass('seeking');
    player.currentTime = offsetPercents($('#progressbar'), event) * player.duration;

    startUpdateProgress();
  };

  $(document).on('mousedown', '#progressbar', function(event){
    if (event.which == 1 && !player.paused){ // left mouse button only
      event.preventDefault();

      stopUpdateProgress();
      $(this).addClass('seeking');
      $(this).find('.slider-value').css('width', offsetPercents($('#progressbar'), event) * 100 + '%');

      $(document).on('mouseup', seekProgressMouseUp);
      $(document).on('mousemove', seekProgressMove);
    }
  });

// volume slider

  var seekVolumeMove = function(event){
    $('#volumebar .slider-value').css('width', offsetPercents($('#volumebar'), event) * 100 + '%');
    player.volume = offsetPercents($('#volumebar'), event);
  };

  var seekVolumeMouseUp = function(event){
    event.preventDefault();

    $(document).off('mouseup', seekVolumeMouseUp);
    $(document).off('mousemove', seekVolumeMove);

    $('#volumebar').removeClass('seeking');
    player.volume = offsetPercents($('#volumebar'), event);
    
    startUpdateProgress();
  };

  $(document).on('mousedown', '#volumebar', function(event){
    if (event.which == 1){ // left mouse button only
      event.preventDefault();
      
      stopUpdateProgress();
      $(this).addClass('seeking');
      $(this).find('.slider-value').css('width', offsetPercents($('#volumebar'), event) * 100 + '%');

      $(document).on('mouseup', seekVolumeMouseUp);
      $(document).on('mousemove', seekVolumeMove);
    }
  });

// other actions

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
      //console.log(url);
      if (url == track_url) {
        playIndex = playlist.length - 1;
      }
    });

    stopUpdateProgress();
    play();
    startUpdateProgress();
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
    stopUpdateProgress();
    playIndex = playIndex + 1;
    if (playIndex < playlist.length) {
      player.currentTime = 0;
      play();
    }
  });
});
