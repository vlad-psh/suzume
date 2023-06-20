<template>
  <div class="vue-abyss">
    <div class="folder-path">
      <NuxtLink to="/abyss/0" class="node">root</NuxtLink
      ><NuxtLink
        v-for="f of parents"
        :key="'parent-' + f[0]"
        :to="'/abyss/' + f[0]"
        class="node"
        >{{ f[1] }}</NuxtLink
      >{{ name }} <a class="button-link" @click="reload">⟳</a>
      <button :disable="!submitting" @click="destroy">🗑️</button>
    </div>

    <template v-if="subfolders && subfolders.length > 0">
      <h2>&#x1f4c1; Folders</h2>
      <div v-for="f of subfolders" :key="'folder-' + f.id">
        <NuxtLink :to="`/abyss/${f.id}`">{{ f.title }}</NuxtLink>
        <NuxtLink
          v-if="f.artist"
          :to="`/artist/${f.artist.id}`"
          class="subfolder-artist"
        >
          {{ f.artist.title }}
        </NuxtLink>
      </div>
    </template>

    <template v-if="release">
      <h2>
        «{{ release.title }}» by
        <NuxtLink :to="`/artist/${artist[0]}`">{{ artist[1] }}</NuxtLink>
      </h2>
      <Release :payload="release" @play="playTrack"></Release>
    </template>
    <template v-else-if="hasAudio">
      <h2>Link release</h2>
      <AbyssForm :folder-id="id" @update="reload"></AbyssForm>
    </template>

    <template v-if="files && files.length > 0">
      <h2>&#x1f4c4; Files</h2>
      <div v-for="f of files" :key="'file-' + f['t']" class="file">
        <div class="ajax-link">{{ f['t'] }}</div>
      </div>
    </template>
  </div>
</template>

<script>
export default {
  async asyncData({ $axios, params }) {
    const resp = await $axios.get(`/api/abyss/${params.id}`)
    return resp.data
  },
  data() {
    return {
      submitting: false,
    }
  },
  computed: {
    hasAudio() {
      return !!(
        this.release ||
        this.files.findIndex((i) => /\.(mp3|m4a)$/.test(i.t)) !== -1
      )
    },
  },
  methods: {
    playTrack(uid) {
      this.$player.playArtist(
        {
          id: this.artist[0],
          title: this.artist[1],
          releases: [this.release],
        },
        uid
      )
    },
    reload() {},
    async destroy() {
      if (!confirm('Are you sure you want to delete this folder?')) return

      this.submitting = true
      await this.$axios.delete(`/api/abyss/${this.id}`)

      const parentId = this.parents[this.parents.length - 1]?.[0] || ''
      this.$router.push(`/abyss/${parentId}`)
    },
  },
}
</script>

<style lang="scss" scoped>
.vue-abyss {
  margin: 0 1em;

  .folder-path {
    .node {
      display: inline-block;

      &:after {
        content: '/';
        color: inherit;
        text-decoration: none;
      }
    }
  }
  .file {
    .now-playing {
      background: #ffffa3;
    }
  }
  .subfolder-artist {
    font-size: 0.8em;
    border-radius: 0.3em;
    text-decoration: none;
    padding: 0.1em 0.5em;
    background: #7771;
    font-weight: bold;

    &:hover {
      background: #7773;
    }
  }

  table.release-form {
    font-size: 0.8em;
    font-family: sans-serif;

    tr.reset {
      cursor: pointer;
      &:hover {
        background-color: #ffffa3;
      }
    }
    th {
      color: #555;
    }
    td {
      text-align: center;
    }
    input {
      border: none;
      font-size: 1.1em;
      border-bottom: 1px solid #ccc;

      &[type='search'] {
        border-color: #08f;
      }
      &[type='button'] {
        border: 1px solid #ccc;
        padding: 0.2em 0.5em;
      }
    }
  }
} // end of .vue-abyss
</style>
