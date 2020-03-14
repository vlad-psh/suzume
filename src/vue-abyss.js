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
  created() {
    this.reloadFolder();
  },
  mounted() {
  },
  template: `
<div class="vue-abyss">
  <div class="folder-path">
    <a @click="openFolder(0)">root</a>/<template v-for="f of j.parents"><a @click="openFolder(f[0])">{{f[1]}}</a>/</template>{{j.name}}
  </div>

  <ul>
    <li v-for="f of j.subfolders" @click="openFolder(f[0])">{{f[1]}}</li>
  </ul>
{{j}}
</div>
`
});
