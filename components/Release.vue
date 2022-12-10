<template>
  <div class="release-component">
    <span class="title">{{ title }}</span>
    <span class="year">{{ year }}</span>
    <NuxtLink :to="`/release/${id}`" class="edit-link">#{{ id }}</NuxtLink>
    <NuxtLink
      v-for="f in folders"
      :key="'folder-link-' + f"
      :to="'/abyss/' + f"
      class="abyss-link"
    >
      {{ f }}
    </NuxtLink>

    <div class="release-container">
      <ReleaseCover :cover="cover" :release-id="id" />

      <div class="release-content">
        <Tracklist :tracks="tracks" @play="(uid) => $emit('play', uid)" />
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
.year {
  color: white;
  font-size: 0.7em;
  vertical-align: text-top;
  margin-top: 0.1em;
  display: inline-block;
  background: #313131;
  padding: 0.05em 0.2em;
  border-radius: 0.2em;
  font-family: sans-serif;
}
.title {
  font-size: 1.2em;
  margin: 0 0 0.5em 0;
}
a.edit-link,
a.abyss-link {
  font-size: 0.65em;
  opacity: 0.6;
  font-weight: normal;
}

.release-component {
  display: block;
  margin-bottom: 1.5em;
}
.release-container {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.5em;
}
</style>
