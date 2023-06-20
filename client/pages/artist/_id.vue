<template>
  <div class="artist-component">
    <div v-if="title" class="title">
      {{ title }}
      <span v-if="romaji" class="alias">{{ romaji }}</span
      ><span v-if="aliases" class="alias">{{ aliases }}</span>
    </div>

    <template v-for="release of releases">
      <Release
        v-if="release.tracks.length > 0"
        :key="'release-' + release.id"
        :payload="release"
        @play="playTrack"
      />
    </template>
  </div>
</template>

<script>
export default {
  async asyncData({ $axios, params }) {
    const resp = await $axios.get(`/api/artist/${params.id}`)
    return resp.data
  },
  methods: {
    playTrack(uid) {
      this.$player.playArtist(this.$data, uid)
    },
  },
}
</script>

<style lang="scss" scoped>
.artist-component {
  margin-left: 1rem;
}

.title {
  font-size: 2.2rem;
  font-weight: bold;
  margin-bottom: 0.7em;

  .alias {
    font-size: 1rem;
    font-weight: normal;
    opacity: 0.3;
  }
  .alias + .alias::before {
    content: ', ';
  }
}
</style>
