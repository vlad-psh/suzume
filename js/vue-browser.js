Vue.component('vue-browser', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      performer: {},
      player: null,
      nowPlaying: null,
      playlist: [],
      upnext: [] // priority tracks
    }
  },
  methods: {
    loadPlaylist(tracks) {
      this.playlist = tracks;
      this.playerStartPlaying();
    },
    addUpnext(track) {
      this.upnext.unshift(track);
    },
    playerTrackEnded() {
      this.playlist.shift();
      this.playerStartPlaying();
    },
    playerStartPlaying() {
      this.nowPlaying = this.upnext.length > 0 ? this.upnext.shift() : this.playlist.shift();
      this.player.setAttribute('src', this.nowPlaying.src);
      this.player.play();
    }
  },
  created() {
    this.performer = this.initData;
  },
  mounted() {
    this.player = $('#main-player2')[0];
  },
  template: `
<div class="vue-browser">
  BROWSER
  <audio id="main-player2" preload="none" @ended="playerTrackEnded" controls="controls" style="width: 500px"></audio>
  <table><tr><td>
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
