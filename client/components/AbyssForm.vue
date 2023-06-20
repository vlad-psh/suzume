<template>
  <div class="abyss-form">
    <div class="artist-form">
      <label>Artist title</label>
      <label>Romaji</label>
      <label>Aliases</label>

      <VueAutosuggest
        v-model="artist.title"
        :suggestions="artist.suggestions"
        :input-props="{ placeholder: 'Artist...' }"
        :get-suggestion-value="(el) => el.item.title"
        @input="artistTitleUpdated"
        @selected="selectArtist"
      >
        <template slot-scope="{ suggestion }">{{
          suggestion.item.title
        }}</template>
      </VueAutosuggest>
      <input v-model="artist.romaji" type="text" :disabled="!!artist.id" />
      <input v-model="artist.aliases" type="text" :disabled="!!artist.id" />
    </div>

    <div class="release-form">
      <label>Release title</label>
      <label>Year</label>
      <label>Romaji</label>
      <label>Release type</label>

      <VueAutosuggest
        v-model="release.title"
        :suggestions="release.suggestions"
        :input-props="{ placeholder: 'Release...' }"
        :get-suggestion-value="(el) => el.item.title"
        @selected="selectRelease"
      >
        <template slot-scope="{ suggestion }">{{
          suggestion.item.title
        }}</template>
      </VueAutosuggest>
      <input v-model="release.year" type="text" :disabled="!!release.id" />
      <input v-model="release.romaji" type="text" :disabled="!!release.id" />
      <input v-model="release.type" type="text" :disabled="!!release.id" />
    </div>

    <button class="submit-button" :disabled="submitting" @click="submit">
      Submit
    </button>
  </div>
</template>

<script>
import { VueAutosuggest } from 'vue-autosuggest'
import { debounce } from '@/js/helpers.js'

export default {
  components: {
    VueAutosuggest,
  },
  props: {
    folderId: { type: Number, required: true },
  },
  data() {
    return {
      artist: {
        id: null,
        title: '',
        romaji: '',
        aliases: '',
        suggestions: [],
      },
      release: {
        id: null,
        year: '',
        title: '',
        romaji: '',
        release_type: '',
        suggestions: [],
      },
      submitting: false,
    }
  },
  created() {
    this.artistTitleUpdated = debounce(this.artistTitleUpdated)
  },
  methods: {
    async submit() {
      const artist = this.artist.id
        ? { id: this.artist.id }
        : {
            title: this.artist.title,
            romaji: this.artist.romaji,
            aliases: this.artist.aliases,
          }

      const release = this.release.id
        ? { id: this.release.id }
        : {
            year: this.release.year,
            title: this.release.title,
            romaji: this.release.romaji,
            release_type: this.release_type,
          }

      if ((!artist.id && !artist.title) || (!release.id && !release.title))
        return

      this.submitting = true

      await this.$axios.post(`/api/abyss/${this.folderId}/link`, {
        artist,
        release,
      })
    },
    async artistTitleUpdated() {
      const resp = await this.$axios.get(
        `/api/autocomplete/artist?query=${encodeURIComponent(
          this.artist.title
        )}`
      )
      this.artist.suggestions = [{ data: resp.data }]
    },
    resetArtist() {
      this.artist.id = null
      this.artist.romaji = ''
      this.artist.aliases = ''

      this.resetRelease()
      this.release.title = '' // TODO: NEEDFIX: This doesn't clear 'Release' autocomplete input field
      this.release.suggestions = []
    },
    selectArtist(el) {
      this.resetArtist()
      this.artist.id = el.item.id
      this.artist.title = el.item.title
      this.artist.aliases = el.item.aliases
      this.artist.romaji = el.item.romaji
      this.release.suggestions = [{ data: el.item.releases }]
    },
    resetRelease() {
      this.release.id = null
      this.release.year = ''
      this.release.romaji = ''
      this.release.release_type = ''
    },
    selectRelease(el) {
      this.release.id = el.item.id
      this.release.year = el.item.year
      // this.release.title = el.item.title
      this.release.romaji = el.item.romaji
      this.release.release_type = el.item.release_type
    },
  },
}
</script>

<style lang="scss" scoped>
.abyss-form {
  display: inline-block;
  text-align: right;
}

.artist-form,
.release-form {
  display: grid;
  column-gap: 0.6em;
  row-gap: 0.3em;
  text-align: left;
}

.artist-form {
  grid-template-columns: 15em 12em 12em;
}

.release-form {
  grid-template-columns: 15em 4em 11em 8.4em;
  margin-top: 0.5em;
}

label {
  font-size: 0.8em;
  font-weight: bold;
  opacity: 0.7;
}

::v-deep input,
button {
  background: white;
  border: 1px solid #bbb;
  padding: 0.4em 0.8em;
  border-radius: 0.3em;
  width: 100%;
  box-sizing: border-box;

  &:disabled {
    background: #eee;
  }
}

.submit-button {
  background: var(--accent-pale-color);
  color: white;
  border: none;
  width: auto;
  margin-top: 1em;
  cursor: pointer;

  &:hover {
    background: var(--accent-color);
  }
}

::v-deep #autosuggest {
  display: inline-block;
  position: relative;

  .autosuggest__results-container {
    position: relative;

    .autosuggest__results {
      position: absolute;
      max-height: 20em;
      min-width: 100%;
      background: white;
      overflow-y: auto;
      border: 1px solid #ccc;
      border-top: none;
      font-size: 0.85em;
      border-radius: 0 0 0.4em 0.4em;
      z-index: 10;
    }

    .autosuggest__results ul {
      list-style: none;
      margin: 0;
      padding: 0;

      .autosuggest__results-item {
        padding: 0.3em 0.8em;
        cursor: pointer;
        white-space: nowrap;

        &--highlighted {
          background: var(--accent-pale-color);
        }
      }
    }
  }
}
</style>
