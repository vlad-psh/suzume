<template>
  <div v-if="tracks.length > 0" class="vue-release">
    <ReleaseCover :cover="cover" :release-id="id" />

    <div class="release-content">
      <span class="release-title"
        >{{ year }} {{ title }}
        <span style="font-size: 0.65em; opacity: 0.4; font-weight: normal"
          >#{{ id }}</span
        >
      </span>

      <Tracklist :tracks="tracks" @play="(uid) => $emit('play', uid)" />

      <div style="font-size: 0.8em; opacity: 0.7">
        <NuxtLink
          v-for="f in folders"
          :key="'folder-link-' + f"
          :to="'/abyss/' + f"
          style="margin-right: 0.5em"
        >
          {{ f }}
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    payload: { type: Object, required: true },
  },
  data() {
    return {
      id: null,
      title: null,
      year: null,
      tracks: [],
      folders: [],
      cover: null,
    }
  },
  created() {
    for (const key of Object.keys(this.payload)) {
      this[key] = this.payload[key]
    }
  },
}
</script>

<style lang="scss" scoped>
.vue-release {
  width: 16em;
  padding: 1em;

  .release-content {
    width: 100%;
  }
}
</style>
