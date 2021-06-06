<template>
  <div class="vue-artist">
    <div v-if="title" class="artist-title">
      {{ title }}
      <span v-if="romaji" class="alias">{{ romaji }}</span
      ><span v-if="aliases" class="alias">{{ aliases }}</span>
    </div>

    <div class="releases-grid">
      <Release
        v-for="release of releases"
        :key="'release-' + release.id"
        :payload="release"
        @play="playTrack"
      ></Release>
    </div>
  </div>
</template>

<script>
export default {
  async asyncData({ $axios, params }) {
    const resp = await $axios.get(`/api/artist/${params.id}`)
    return resp.data
  },
  computed: {
    allTracks() {
      return []
        .concat(...this.releases.map((i) => i.tracks))
        .map((i) => this.trackObject(i))
    },
  },
  methods: {
    playTrack2(uid) {
      // add single track to queue and start playing (if player is stopped)
      const track = this.allTracks.find((i) => i.uid === uid)
      this.$emit('add', track)
    },
    playTrack(uid) {
      this.$player.startPlaylist(this.allTracks, uid)
    },
    trackObject(track) {
      return {
        uid: track.uid,
        title: track.title,
        artist: this.title,
        rating: track.rating,
        src: `/download/audio/${track.uid}`,
      }
    },
  },
}
</script>

<style lang="scss" scoped>
.vue-artist {
  .artist-title {
    font-size: 2.2rem;
    font-weight: bold;
    margin-left: 1rem;

    .alias {
      font-size: 1rem;
      font-weight: normal;
      opacity: 0.3;
    }
    .alias + .alias::before {
      content: ', ';
    }
  }

  .releases-grid {
    display: flex;
    //justify-content: space-evenly;
    flex-wrap: wrap;
  }
}
</style>
