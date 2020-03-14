Vue.component('vue-browser', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      mode: 'index',
      performer: {},
      performers: [],
      filterValue: '',
      abyssFolderId: 0,
      playlist: [],
    }
  },
  methods: {
    reloadIndex() {
      $.ajax({
        url: `/api/index`,
        method: 'GET'
      }).done(data => {
        this.performers = JSON.parse(data);
      });
    },
    openPerformer(id) {
      $.ajax({
        url: `/api/performer/${id}`,
        method: 'GET'
      }).done(data => {
        this.performer = JSON.parse(data);
        this.mode = 'performer';
      });
    },
    addTrack(track) {
      this.playlist.push(track);
      this.$refs.player.addTrack(track);
    },
  }, // end of methods()
  computed: {
    filteredPerformers() {
      if (this.filterValue) {
        var r = new RegExp(this.filterValue, 'i');
        return this.performers.filter(i => i.title.match(r) || (i.aliases && i.aliases.match(r)));
      } else {
        return this.performers;
      }
    }
  },
  created() {
    if (this.initData.performer) this.performer = this.initData.performer;
    if (this.initData.performers) this.performers = this.initData.performers;
  },
  mounted() {
  },
  template: `
<div class="vue-browser">
  <vue-player ref="player"></vue-player>

  <div class="browser-grid-layout">
    <div class="browser-content">

      <template v-if="mode === 'index'">
        <input v-model="filterValue">
        <div class="performers-list">
          <div v-for="p in filteredPerformers"><a class="ajax-link" @click="openPerformer(p.id)">{{p.title}}</a></div>
        </div>
      </template>

      <template v-else-if="mode === 'performer'">
        <vue-performer :init-data="performer" :now-playing="$refs.player.nowPlaying ? $refs.player.nowPlaying.uid : null" @play-track="addTrack($event)"></vue-performer>
      </template>

      <template v-else-if="mode === 'abyss'">
        <vue-abyss :id="abyssFolderId" @open="abyssFolderId = $event"></vue-abyss>
      </template>
    </div>

    <div class="queue-manager">
      <h3>Playlist:</h3>
      <table>
        <tr v-for="(track, trackIndex) in playlist" class="queue-track" :class="track.origin" @click="$refs.player.playerStartPlaying(trackIndex)">
          <td>
            <template v-if="$refs.player.nowPlaying.uid === track.uid && $refs.player.playerStatus === 'playing'">
              <div v-for="bar in [1,2,3,4]" class="eq-bar"></div>
            </template>
            <template v-else>{{track.rating}}</template>
          </td>
          <td>{{track.title}}<br><span class="performer">{{track.performer}}</span></td>
        </tr>
      </table>
    </div>
  </div>
</div>
`
});
