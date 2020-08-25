import helpers from './helpers.js';

Vue.component('vue-artist', {
  props: {
    initData: {type: Object, required: false},
    nowPlaying: {type: String, required: false}
  },
  data() {
    return {
      id: null, title: null, aliases: null, romaji: null, releases: []
    }
  },
  computed: {
    allTracks() {
      return [].concat(...this.releases.map(i => i.tracks)).map(i => this.trackObject(i));
    }
  },
  methods: {
    playTrack2(uid) { // emitted by vue-release
      const track = this.allTracks.find(i => i.uid === uid);
      this.$emit('add', track);
    },
    playTrack(uid) {
      const all = this.allTracks;
      var idx = all.findIndex(i => i.uid === uid);
      this.$emit('start', this.splitArray(all, idx));
    },
    trackObject(track) {
      return {
        uid: track.uid,
        title: track.title,
        artist: this.title,
        rating: track.rating,
        src: `/download/audio/${track.uid}`
      };
    },
    openAbyss(id) {
      this.$emit('abyss', id);
    },
    ...helpers
  },
  created() {
    for (var key of Object.keys(this._data)) {
      this[key] = this.initData[key];
    }
  },
  mounted() {
  },
  template: `
<div class="vue-artist">
  <div class="artist-title">{{title}} <span class="artist-aliases">{{romaji}}<template v-if="romaji && aliases">, </template>{{aliases}}</span></div>

  <div class="releases-grid">
    <vue-release v-for="release of releases" :init-data="release" :now-playing="nowPlaying" @start="playTrack" :key="'release_' + release.id"></vue-release>
  </div>
</div>
`
});
