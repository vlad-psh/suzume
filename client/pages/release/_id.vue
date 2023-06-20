<template>
  <div class="release-page">
    <h1>{{ title }} [{{ year }}]</h1>

    <div class="image-list">
      <div
        v-for="image of images"
        :key="image.folder_id + image.filename"
        class="image-item"
      >
        <a :href="`/download/abyss/${image.folder_id}/${image.filename}`"
          ><img :src="`/download/abyss/${image.folder_id}/${image.filename}`"
        /></a>
        {{ image.filesize }}
        <button @click="setCover(image)">Set</button>
      </div>
    </div>

    <div class="container">
      <div class="editor">
        <textarea v-model="editorText" class="editable-tracklist" />

        <div class="replace-form">
          <input v-model="pattern" />
          <input v-model="replacement" />
          <input type="button" value="Replace" @click="replace" />
        </div>

        <button @click="pattern = '\\.mp3$'">.mp3</button>
        <button @click="pattern = '^\\d{1,2}\\.\\s*'">01.</button>
      </div>

      <table>
        <tr v-for="(track, index) of tracks" :key="track.uid">
          <td>{{ track.title }}</td>
          <td>{{ editorArray[index] }}</td>
        </tr>
      </table>
    </div>

    <button @click="submit" class="submit-btn">Submit</button>
  </div>
</template>

<script>
import { sortObjectsArray } from '@/js/helpers.js'

export default {
  async asyncData({ $axios, params }) {
    const resp = await $axios.get(`/api/release/${params.id}`)
    const release = resp.data.release
    const tracks = sortObjectsArray(release.tracks, 'filename')

    return {
      id: params.id,
      title: release.title,
      year: release.year,
      tracks,
      images: resp.data.images,
      editorText: tracks.map((track) => track.title).join('\n'),
    }
  },
  data() {
    return {
      id: null,
      title: null,
      year: null,
      tracks: [],
      images: [],
      editorText: '',
      pattern: '\\.mp3$',
      replacement: '',
    }
  },
  computed: {
    editorArray() {
      return this.editorText.split('\n')
    },
  },
  methods: {
    async submit() {
      const reqData = {}

      for (const i in this.tracks) {
        reqData[this.tracks[i].uid] = this.editorArray[i]
      }

      await this.$axios.patch('/api/tracks', { tracks: reqData })
    },
    replace() {
      this.editorText = this.editorArray
        .map((i) => i.replace(new RegExp(this.pattern, 'g'), this.replacement))
        .join('\n')
    },
    async setCover(image) {
      await this.$axios.post(`/api/release/${this.id}/cover`, {
        folder_id: image.folder_id,
        filename: image.filename,
      })
    },
  },
}
</script>

<style lang="scss" scoped>
.image-list {
  display: flex;

  .image-item {
    display: flex;
    max-width: 150px;
    flex-direction: column;
    align-items: center;

    img {
      width: 100%;
    }
  }
}
.editable-tracklist {
  width: 100%;
  height: 30em;
  box-sizing: border-box;
  white-space: pre;
  overflow-x: auto;
}
.container {
  display: grid;
  grid-template-columns: 1fr 2fr;
}
.replace-form {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 0.5em;

  input {
    min-width: 5em;
  }
}
table {
  tr:nth-child(odd) {
    background: #f1f1f1;
  }
}
.submit-btn {
  float: right;
  margin-top: 1em;
}
</style>
