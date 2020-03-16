import helpers from './helpers.js';

Vue.component('vue-abyss', {
  props: {
    id: {type: Number, required: true},
    nowPlaying: {type: String, required: false},
  },
  data() {
    return {
      j: {},
    }
  },
  watch: {
    id(val) {
      this.reloadFolder();
    }
  },
  computed: {
    allRecords() {
      return this.j.files.filter(i => i.type === 'audio').map(i => this.recordObject(i));
    },
    allImages() {
      return this.j.files.filter(i => i.type === 'image');
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
    recordObject(record) {
      return {
        //uid: record.uid,
        md5: record.md5,
        title: record.fln,
        //performer: this.title,
        rating: record.rating,
        src: `/abyss/${this.id}/file/${record.md5}`
      };
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
    <br>
    <div class="folder" v-for="f of j.subfolders"><div class="ajax-link" @click="openFolder(f[0])">{{f[1]}}</div><template v-if="f[2]"> by {{f[2][1]}}</template></div>
  </template>

  <template v-if="allRecords.length > 0">
    <h2>&#x1f3b6; Audio</h2>
    <div class="file" v-for="f of allRecords">
      <vue-rating-button :track="f"></vue-rating-button>
      <div class="ajax-link" :class="nowPlaying === f.md5 ? 'now-playing' : ''" @click="start(f.md5)">{{f.title}}</div>
    </div>
  </template>

  <template v-if="allImages.length > 0">
    <h2>&#x1f5bc;&#xfe0f; Images</h2>
    <div class="file" v-for="f of allImages"><div class="ajax-link">{{f.fln}}</div></div>
  </template>

  <template v-if="allOther.length > 0">
    <h2>&#x1f4c4; Files</h2>
    <div class="file" v-for="f of allOther"><div class="ajax-link">{{f.fln}}</div></div>
  </template>
</div>
`
});
