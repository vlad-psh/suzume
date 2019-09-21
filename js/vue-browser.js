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
      this.player.setAttribute('src', tracks[0].src);
      this.player.play();
      this.nowPlaying = tracks[0].uid;
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
  <audio id="main-player2" preload="none"></audio>
  <table><tr><td>
  <vue-performer :init-data="performer" :now-playing="nowPlaying" @load-playlist="loadPlaylist($event)"></vue-performer>
  </td><td>
    <ul>
      <li v-for="track in playlist">{{track.title}}</li>
    </ul>
  </td></tr></table>
</div>
`
});
