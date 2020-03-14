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
        rating: this.ratingEmoji(record.rating + 1),
        src: `/download/audio/${record.uid}`
      };
    },
    coverThumb(id) {
      return `/download/image/${id}/thumb`;
    },
    coverOrig(id) {
      return `/download/image/${id}/cover`
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
    <template v-for="release of releases">
      <div v-if="release.records.length > 0" class="release-container">
        <div class="release-cover">
          <template v-if="release.cover">
            <a class="cover-link" :href="coverOrig(release.id)"><div class="thumbnail"><img :src="coverThumb(release.id)"></div></a>
          </template>
          <template v-else><div class="thumbnail"></div></template>
        </div>
        <div class="release-content">
          <span class="release-title">{{release.year}} {{release.title}}
            <span style="font-size: 0.65em; opacity: 0.4; font-weight: normal;">#{{release.id}}</span>
          </span>
          <table class="records-table">
            <tr v-for="record of release.records" class="record-line">
              <td class="rating"><span class="rating-choose-button">{{ratingEmoji(record.rating + 1)}}</span></td>
              <td class="trackname" :class="nowPlaying == record.uid ? 'track-now-playing' : null"><a :href="'download/audio/' + record.uid" @click.prevent="playTrack(record.uid)">{{record.title}}</a></td>
              <td class="duration">{{record.dur}}</td>
            </tr>
          </table>
        </div>
      </div>
    </template>
  </div>
</div>
`
});
