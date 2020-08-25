import Autocomplete from 'v-autocomplete';
Vue.use(Autocomplete);

// artist = ArtistAutoComplete methods
Vue.component('vue-abyss-release-form', {
  props: {
    id: {type: Number, required: true},
  },
  data() {
    return {
      artist: {title: null, romaji: null, aliases: null, list: [], item: null},
      release: {title: null, romaji: null, year: null, format: null, type: null, list: [], item: null},
    }
  },
  computed: {
    readyToSubmit() {
      return ((this.artist.item || this.artist.title) && (this.release.item || this.release.title)) ? true : false;
    },
  },
  methods: {
    submit() {
      const formData = new FormData();
      var i; // for loops

      if (this.artist.item) {
        formData.append('artist_id', this.artist.item.id);
      } else {
        for (i of ['title', 'romaji', 'aliases'])
          if (this.artist[i]) formData.append(`artist_${i}`, this.artist[i]);
      }

      if (this.release.item) {
        formData.append('release_id', this.release.item.id);
      } else {
        for (i of ['title', 'year', 'romaji', 'format', 'type'])
          if (this.release[i]) formData.append(`release_${i}`, this.release[i]);
      }

      fetch(`/abyss/${this.id}/info`, {method: 'POST', body: formData})
        .then((response) => response.json())
        .then((result) => {
          this.$emit('update');
        });
    },
    artistSearch(val) {
      this.artist.title = val;
      fetch(`/autocomplete/artist?term=${val}`)
        .then((response) => response.json())
        .then((result) => this.artist.list = result)
    },
    artistReset() {
      this.releaseReset();
      this.artist.item = null;
      this.artist.title = null;
      this.artist.list = [];
    },
    releaseSearch(val) {
      this.release.title = val;
      fetch(`/autocomplete/artist/${this.artist.item.id}/release?term=${val}`)
        .then((response) => response.json())
        .then((result) => this.release.list = result)
    },
    releaseReset() {
      this.release.item = null;
      this.release.title = null;
      this.release.list = [];
    },
  },
  template: `
<table class="release-form">
  <tr>
    <th>ID</th><th>Artist Name</th><th>Romaji</th><th>Aliases</th>
  </tr>
  <tr v-if="artist.item" @click="artistReset" class="reset">
    <td>#{{artist.item.id}}</td><td>{{artist.item.value}}</td><td>{{artist.item.romaji}}</td><td>{{artist.item.aliases}}</td>
  </tr>
  <tr v-else>
    <td>NEW</td>
    <td><v-autocomplete :items="artist.list" @update-items="artistSearch" :get-label="i => i.value" @item-selected="artist.item = $event" :auto-select-one-item="false" :min-len="1" :keep-open="false" :key="'artist' + id"></v-autocomplete></td>
    <td><input v-model="artist.romaji"></td>
    <td><input v-model="artist.aliases"></td>
  </tr>
  <tr>
    <th>ID</th><th>Release Title</th><th>Romaji</th><th>Year</th><th>Edition</th><th>Release Type</th>
  </tr>
  <tr v-if="release.item" @click="releaseReset" class="reset">
    <td>{{release.item.id}}</td><td>{{release.item.value}}</td><td>{{release.item.romaji}}</td><td>{{release.item.year}}</td><td></td><td>{{release.item.rtype}}</td>
  </tr>
  <tr v-else>
    <td>NEW</td>
    <td>
      <v-autocomplete v-if="artist.item" :items="release.list" @update-items="releaseSearch" :get-label="i => i.value" @item-selected="release.item = $event" :auto-select-one-item="false" :min-len="1" :keep-open="false" :key="'release' + id"></v-autocomplete>
      <input v-else v-model="release.title">
    </td>
    <td><input v-model="release.romaji"></td>
    <td><input v-model="release.year"></td>
    <td><input v-model="release.format"></td>
    <td><input v-model="release.type"></td>
  </tr>
  <tr>
    <td></td><td></td><td></td><td></td><td></td><td><input value="Submit" type="button" @click="submit" :disabled="!readyToSubmit"></td>
  </tr>
</table>
`
});
