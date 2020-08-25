import helpers from './helpers.js';

Vue.component('vue-abyss', {
  props: {
    id: {type: Number, required: true},
    nowPlaying: {type: String, required: false},
  },
  data() {
    return {
      j: {files: []},
    }
  },
  watch: {
    id(val) {
      this.reloadFolder();
    }
  },
  computed: {
    hasAudio() {
      return this.j.release || this.j.files.findIndex(i => /\.(mp3|m4a)$/.test(i.t)) !== -1 ? true : false;
    }
  },
  methods: {
    reloadFolder() {
      $.ajax({
        url: `/api/abyss/${this.id}`,
        method: 'GET'
      }).done(data => {
        this.j = JSON.parse(data);
      });
    },
    openFolder(id) {
      this.$emit('open', id);
    },
    releaseUpdated() {
      this.reloadFolder();
    },
    ...helpers
  },
  created() {
    this.reloadFolder();
  },
  mounted() {
  },
  template: `
<div class="vue-abyss">
  <div class="folder-path">
    <div class="node"><div class="ajax-link" @click="openFolder(0)">root</div></div><div class="node" v-for="f of j.parents"><div class="ajax-link" @click="openFolder(f[0])">{{f[1]}}</div></div>{{j.name}} <a class="button-link" @click="reloadFolder">⟳</a>
  </div>

  <template v-if="j.subfolders && j.subfolders.length > 0">
    <h2>&#x1f4c1; Folders</h2>
    <div class="folder" v-for="f of j.subfolders"><div class="ajax-link" @click="openFolder(f[0])">{{f[1]}}</div><template v-if="f[2]"> by {{f[2][1]}}</template></div>
  </template>

  <template v-if="j.release">
    <h2>«{{j.release.title}}» by {{j.performer[1]}}</h2>
    <vue-release :init-data="j.release"></vue-release>
  </template>
  <template v-else-if="hasAudio">
    <h2>Link release</h2>
    <vue-abyss-release-form :id="id" @update="releaseUpdated"></vue-abyss-release-form>

    <template v-if="j.files && j.files.length > 0">
      <h2>&#x1f4c4; Files</h2>
      <div class="file" v-for="f of j.files"><div class="ajax-link">{{f['t']}}</div></div>
    </template>
  </template>
</div>
`
});
