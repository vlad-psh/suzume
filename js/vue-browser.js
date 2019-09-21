Vue.component('vue-browser', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      performer: {},
      playlist: [],
      upnext: [] // priority tracks
    }
  },
  methods: {
  },
  created() {
    this.performer = this.initData;
  },
  template: `
<div class="vue-browser">
  BROWSER
  <vue-performer :init-data="performer"></vue-performer>
</div>
`
});
