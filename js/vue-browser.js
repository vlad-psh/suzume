Vue.component('vue-browser', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      performer: {},
      performers: [],
      player: null,
      nowPlaying: null,
      playlist: [],
      upnext: [] // priority tracks
    }
  },
  methods: {
    loadPlaylist(tracks) {
      this.playlist = tracks;
      this.playerStartPlaying(true);
    },
    addUpnext(track) {
      this.upnext.unshift(track);
      if (this.playerStopped()) this.playerStartPlaying(false);
    },
    playerStartPlaying(skipUpnext) {
      if (this.upnext.length > 0 || this.playlist.length > 0) {
        if (skipUpnext) {
          this.nowPlaying = this.playlist.length > 0 ? this.playlist.shift() : this.upnext.shift();
        } else {
          this.nowPlaying = this.upnext.length > 0 ? this.upnext.shift() : this.playlist.shift();
        }
        this.player.setAttribute('src', this.nowPlaying.src);
        this.player.play();
      } else {
        this.nowPlaying = null;
      }
    },
    openIndex() {
      $.ajax({
        url: `/api/index`,
        method: 'GET'
      }).done(data => {
        this.performer = {};
        this.performers = JSON.parse(data);
      });
    },
    openPerformer(id) {
      $.ajax({
        url: `/api/performer/${id}`,
        method: 'GET'
      }).done(data => {
        this.performers = [];
        this.performer = JSON.parse(data);
      });
    },
    playerStopped() {
      return this.player.src === '' || this.player.ended === true;
    }
  },
  created() {
    if (this.initData.performer) this.performer = this.initData.performer;
    if (this.initData.performers) this.performers = this.initData.performers;
  },
  mounted() {
    this.player = $('#main-player2')[0];
  },
  template: `
<div class="vue-browser">
  <a class="ajax-link" @click="openIndex">Index</a>
  <br>
  <audio id="main-player2" preload="none" @ended="playerStartPlaying(false)" controls="controls" style="width: 500px"></audio>

  <ul v-if="performers.length > 0" class="performers-list">
    <li v-for="p in performers"><a class="ajax-link" @click="openPerformer(p.id)">{{p.title}}</a></li>
  </ul>

  <table v-if="performer.id"><tr><td>
  <vue-performer :init-data="performer" :now-playing="nowPlaying ? nowPlaying.uid : null" @load-playlist="loadPlaylist($event)" @upnext="addUpnext($event)"></vue-performer>
  </td><td>
    <ul>
      <li v-if="nowPlaying">&gt;&gt; {{nowPlaying.title}}</li>
      <li v-for="track in upnext" style="background: rgba(255,255,0,0.2)">{{track.title}}</li>
      <li v-for="track in playlist">{{track.title}}</li>
    </ul>
  </td></tr></table>
</div>
`
});
