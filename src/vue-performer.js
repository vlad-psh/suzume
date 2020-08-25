import helpers from './helpers.js';

Vue.component('vue-performer', {
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
    allRecords() {
      return [].concat(...this.releases.map(i => i.records)).map(i => this.recordObject(i));
    }
  },
  methods: {
    playTrack2(uid) { // emitted by vue-release
      const record = this.allRecords.find(i => i.uid === uid);
      this.$emit('add', record);
    },
    playTrack(uid) {
      const all = this.allRecords;
      var idx = all.findIndex(i => i.uid === uid);
      this.$emit('start', this.splitArray(all, idx));
    },
    recordObject(record) {
      return {
        uid: record.uid,
        title: record.title,
        performer: this.title,
        rating: record.rating,
        src: `/download/audio/${record.uid}`
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
<div class="vue-performer">
  <div class="performer-title">{{title}} <span class="performer-aliases">{{romaji}}<template v-if="romaji && aliases">, </template>{{aliases}}</span></div>

  <div class="releases-grid">
    <vue-release v-for="release of releases" :init-data="release" :now-playing="nowPlaying" @start="playTrack" :key="'release_' + release.id"></vue-release>
  </div>
</div>
`
});
