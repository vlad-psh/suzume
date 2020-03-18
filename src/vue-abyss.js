import helpers from './helpers.js';

Vue.component('vue-abyss', {
  props: {
    id: {type: Number, required: true},
    nowPlaying: {type: String, required: false},
  },
  data() {
    return {
      j: {files: []},
      cover: null,
      coverUrl: null,
    }
  },
  watch: {
    id(val) {
      this.reloadFolder();
    }
  },
  computed: {
    allRecords() {
      return this.j.files.filter(i => i.type === 'audio').map(i => new Object({
        md5: i.md5,
        title: i.fln,
        rating: i.rating,
        src: `/abyss/${this.id}/file/${i.md5}`,
      }));
    },
    allImages() {
      return this.j.files.filter(i => i.type === 'image').map(i => new Object({
        md5: i.md5,
        fln: i.fln,
        cover: i.cover ? true : false,
      }));
    },
    allOther() {
      return this.j.files.filter(i => i.type === undefined);
    },
  },
  methods: {
    reloadFolder() {
      $.ajax({
        url: `/api/abyss/${this.id}`,
        method: 'GET'
      }).done(data => {
        this.j = JSON.parse(data);
        this.cover = this.allImages.find(i => i.cover === true);
      });
    },
    openFolder(id) {
      this.$emit('open', id);
    },
    start(md5) {
      const all = this.allRecords;
      const idx = all.findIndex(i => i.md5 === md5);
      this.$emit('start', this.splitArray(all, idx));
    },
    releaseUpdated() {
      this.reloadFolder();
    },
    setCover(md5) {
      fetch(`/abyss/${this.id}/set_cover/${md5}`, {method: 'POST'})
        .then((response) => {
          // TODO: change cover without reload
          this.reloadFolder();
        })
    },
    downloadCover() {
      if (!this.coverUrl) return false;
      var data = new FormData();
      data.append('url', this.coverUrl);
      this.coverUrl = null;

      fetch(`/abyss/${this.id}/download_cover`, {method: 'POST', body: data})
        .then((response) => {
          // TODO: without reloading
          this.reloadFolder()
        });
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

  <div v-if="j.release">«{{j.release[1]}}» by {{j.performer[1]}}</div>

  <template v-if="j.subfolders && j.subfolders.length > 0">
    <h2>&#x1f4c1; Folders</h2>
    <div class="folder" v-for="f of j.subfolders"><div class="ajax-link" @click="openFolder(f[0])">{{f[1]}}</div><template v-if="f[2]"> by {{f[2][1]}}</template></div>
  </template>

  <template v-if="allRecords.length > 0">
    <h2>&#x1f3b6; Audio</h2>
    <div class="file" v-for="f of allRecords">
      <vue-rating-button :track="f"></vue-rating-button>
      <div class="ajax-link" :class="nowPlaying === f.md5 ? 'now-playing' : ''" @click="start(f.md5)">{{f.title}}</div>
    </div>
  </template>

  <template v-if="allRecords.length > 0 || allImages.length > 0">
    <h2>&#x1f5bc;&#xfe0f; Images</h2>
    <div class="file" v-for="f of allImages">
      <div class="emoji" @click="setCover(f.md5)">{{f.cover ? '※' : '・'}}</div> <div class="ajax-link">{{f.fln}}</div>
    </div>
    <input v-model="coverUrl" @keydown.enter="downloadCover">
    <input type="button" @click="downloadCover" value="Download">
  </template>

  <template v-if="allOther.length > 0">
    <h2>&#x1f4c4; Files</h2>
    <div class="file" v-for="f of allOther"><div class="ajax-link">{{f.fln}}</div></div>
  </template>

  <br>
  <vue-abyss-release-form v-if="!j.release && allRecords.length > 0" :id="id" @update="releaseUpdated"></vue-abyss-release-form>
</div>
`
});
