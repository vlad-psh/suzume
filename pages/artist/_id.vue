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
