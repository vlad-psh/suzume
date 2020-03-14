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
        //rating: this.ratingEmoji(record.rating + 1),
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
    <div class="node"><div class="ajax-link" @click="openFolder(0)">root</div></div><div class="node" v-for="f of j.parents"><div class="ajax-link" @click="openFolder(f[0])">{{f[1]}}</div></div>{{j.name}}
  </div>

  <template v-if="j.subfolders && j.subfolders.length > 0">
    <br>
    <div class="folder" v-for="f of j.subfolders" @click="openFolder(f[0])"><div class="ajax-link">{{f[1]}}</div></div>
  </template>

  <template v-if="j.files && j.files.length > 0">
    <h2>Files</h2>
    <div class="file" v-for="f of j.files"><div class="ajax-link" :class="nowPlaying === f.md5 ? 'now-playing' : ''" @click="start(f.md5)">{{f.fln}}</div></div>
  </template>
</div>
`
});
