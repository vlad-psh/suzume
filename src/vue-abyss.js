function compare(a, b, reverse = false) {
  return a > b ? (reverse ? -1 : 1) : (a < b ? (reverse ? 1 : -1) : 0);
}

Vue.component('vue-abyss', {
  props: {
    id: {type: Number, required: true},
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
    }
  },
  computed: {
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
    <div class="file" v-for="f of j.files"><div class="ajax-link">{{f.fln}}</div></div>
  </template>
</div>
`
});
