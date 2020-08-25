import helpers from './helpers.js';

Vue.component('vue-release', {
  props: {
    initData: {type: Object, required: true},
    nowPlaying: {type: String, required: false},
  },
  data() {
    return {
      id: null, title: null, year: null, tracks: [], folders: [], cover: null
    }
  },
  computed: {
    coverThumb() {
      return `/download/image/${this.id}/thumb`;
    },
    coverOrig() {
      return `/download/image/${this.id}/cover`
    },
  },
  methods: {
    playTrack(uid) {
      this.$emit('start', uid);
    },
    openAbyss(id) {
      // TODO: fix
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
<div v-if="tracks.length > 0" class="vue-release">
  <div class="release-cover">
    <template v-if="cover">
      <a class="cover-link" :href="coverOrig"><div class="thumbnail"><img :src="coverThumb"></div></a>
    </template>
    <template v-else><div class="thumbnail"></div></template>
  </div>
  <div class="release-content">
    <span class="release-title">{{year}} {{title}}
      <span style="font-size: 0.65em; opacity: 0.4; font-weight: normal;">#{{id}}</span>
    </span>
    <table class="tracks-table">
      <tr v-for="track of tracks" class="track-line">
        <td class="rating"><vue-rating-button :track="track"></vue-rating-button></td>
        <td class="trackname" :class="nowPlaying == track.uid ? 'track-now-playing' : null"><a :href="'download/audio/' + track.uid" @click.prevent="playTrack(track.uid)">{{track.title}}</a></td>
        <td class="duration">{{track.dur}}</td>
      </tr>
    </table>
    <div style="font-size: .8em;opacity:.7">
      <a v-for="f in folders" @click="openAbyss(f)" style="margin-right: .5em">{{f}}</a>
    </div>
  </div>
</div>
`
});
