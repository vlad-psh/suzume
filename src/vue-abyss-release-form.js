import Autocomplete from 'v-autocomplete';
Vue.use(Autocomplete);

// performer = PerformerAutoComplete methods
Vue.component('vue-abyss-release-form', {
  props: {
    id: {type: Number, required: true},
  },
  data() {
    return {
      performer: {title: null, romaji: null, aliases: null, list: [], item: null},
      release: {title: null, romaji: null, year: null, format: null, type: null, list: [], item: null},
    }
  },
  computed: {
    readyToSubmit() {
      return ((this.performer.item || this.performer.title) && (this.release.item || this.release.title)) ? true : false;
    },
  },
  methods: {
    submit() {
      const formData = new FormData();
      var i; // for loops

      if (this.performer.item) {
        formData.append('performer_id', this.performer.item.id);
      } else {
        for (i of ['title', 'romaji', 'aliases'])
          formData.append(`performer_${i}`, this.performer[i]);
      }

      if (this.release.item) {
        formData.append('release_id', this.release.item.id);
      } else {
        for (i of ['title', 'year', 'romaji', 'format', 'type'])
          formData.append(`release_${i}`, this.release[i]);
      }

      fetch(`/abyss/${this.id}/info`, {method: 'POST', body: formData})
        .then((response) => response.json())
        .then((result) => {
          this.$emit('update');
        });
    },
    performerSearch(val) {
      this.performer.title = val;
      fetch(`/autocomplete/performer?term=${val}`)
        .then((response) => response.json())
        .then((result) => this.performer.list = result)
    },
    performerReset() {
      this.releaseReset();
      this.performer.item = null;
      this.performer.title = null;
      this.performer.list = [];
    },
    releaseSearch(val) {
      this.release.title = val;
      fetch(`/autocomplete/performer/${this.performer.item.id}/release?term=${val}`)
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
<table v-else-if="allRecords.length > 0" class="release-form">
  <tr>
    <th>ID</th><th>Performer Name</th><th>Romaji</th><th>Aliases</th>
  </tr>
  <tr v-if="performer.item" @click="performerReset" class="reset">
    <td>#{{performer.item.id}}</td><td>{{performer.item.value}}</td><td>{{performer.item.romaji}}</td><td>{{performer.item.aliases}}</td>
  </tr>
  <tr v-else>
    <td>NEW</td>
    <td><v-autocomplete :items="performer.list" @update-items="performerSearch" :get-label="i => i.value" @item-selected="performer.item = $event" :auto-select-one-item="false" :min-len="1" :keep-open="false" :key="'performer' + id"></v-autocomplete></td>
    <td><input v-model="performer.romaji"></td>
    <td><input v-model="performer.aliases"></td>
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
      <v-autocomplete v-if="performer.item":items="release.list" @update-items="releaseSearch" :get-label="i => i.value" @item-selected="release.item = $event" :auto-select-one-item="false" :min-len="1" :keep-open="false" :key="'release' + id"></v-autocomplete>
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
