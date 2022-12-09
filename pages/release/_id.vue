<template>
  <div class="release-page">
    <h1>{{ title }} [{{ year }}]</h1>

    <div class="container">
      <div class="editor">
        <textarea v-model="editorText" class="editable-tracklist" />

        <div class="replace-form">
          <input v-model="pattern" />
          <input v-model="replacement" />
          <input type="button" @click="replace" value="Replace" />
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
    const tracks = sortObjectsArray(resp.data.tracks, 'filename')

    return {
      title: resp.data.title,
      year: resp.data.year,
      tracks,
      editorText: tracks.map((track) => track.title).join('\n'),
    }
  },
  data() {
    return {
      title: null,
      year: null,
      tracks: [],
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

      const resp = await this.$axios.patch('/api/tracks', { tracks: reqData })
      console.log(resp)
    },
    replace() {
      this.editorText = this.editorArray
        .map((i) => i.replace(new RegExp(this.pattern, 'g'), this.replacement))
        .join('\n')
    },
  },
}
</script>

<style lang="scss" scoped>
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
