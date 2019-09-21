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
  methods: {
    ratingEmoji(rating) {
      // 274c, 2753, 1f3b5, 2b50, 1f496
      return ['\u274c', '\u2753', '\ud83c\udfb5', '\u2b50', '\ud83d\udc96'][rating];
    },
    playSong(uid) { // emitted by vue-release
      var tracks = [];
      var appending = false;
      for (release of this.releases) {
        for (record of release.records) {
          if (record.uid === uid) appending = true;
          if (appending === true) tracks.push({
            uid: record.uid,
            title: record.title,
            src: `/download/audio/${record.uid}`
          });
        }
      }
      this.$emit('load-playlist', tracks);
    },
    coverThumb(id) {
      return `/download/image/${id}/thumb`;
    },
    coverOrig(id) {
      return `/download/image/${id}/cover`
    }
  },
  created() {
    for (key of Object.keys(this._data)) {
      this[key] = this.initData[key];
    }
  },
  template: `
<div class="vue-performer">
  PERFORMER {{title}}
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
          <span style="font-size: 0.65em; opacity: 0.4; font-weight: normal;">#{{id}}</span>
        </span>
        <div v-for="record of release.records">
          <span class="rating-choose-button">{{ratingEmoji(record.rating + 1)}}</span>
          <a class="ajax-link" :class="nowPlaying == record.uid ? 'track-now-playing' : null" @click="playSong(record.uid)">{{record.title}}</a>
        </div>
      </div>
    </div>
  </template>
</div>
`
});
