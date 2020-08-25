window.Vue = require('vue');
require("jquery-ui/ui/widgets/autocomplete.js");

require('./vue-browser.js');
require('./vue-player.js');
require('./vue-performer.js');
require('./vue-release.js');
require('./vue-abyss.js');
require('./vue-rating-button.js');
require('./vue-abyss-release-form.js');

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

