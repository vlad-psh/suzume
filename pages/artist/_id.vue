<template>
  <div class="vue-artist">
    <div class="artist-title">
      {{ title }}
      <span class="artist-aliases"
        >{{ romaji }}<template v-if="romaji && aliases">, </template
        >{{ aliases }}</span
      >
    </div>

    <div class="releases-grid">
      <Release
        v-for="release of releases"
        :key="'release-' + release.id"
        :payload="release"
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
}
</script>

<style lang="scss" scoped>
.vue-artist {
  .artist-title {
    font-size: 2.2rem;
    font-weight: bold;
    margin-left: 1rem;

    .artist-aliases {
      font-size: 1rem;
      font-weight: normal;
      opacity: 0.3;
    }
  }

  .releases-grid {
    display: flex;
    //justify-content: space-evenly;
    flex-wrap: wrap;
  }
}
</style>
