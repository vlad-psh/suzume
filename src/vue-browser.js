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
      tracklists: {playlist: [], simple: []},
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
      this.tracklists.playlist.push(track);
      this.$refs.player.trackAddedToPlaylist();
    },
    startSimplePlaying(tracklist) {
      this.tracklists.simple = tracklist;
      this.$refs.player.startSimple();
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
  <vue-player ref="player" :tracklists="tracklists"></vue-player>

  <div class="menu" style="position: fixed; top: 0; left: 0;">
    <a class="ajax-link" @click="mode = 'index'">Index</a>
    <a class="ajax-link" @click="mode = 'abyss'">Abyss</a>
  </div>


  <div class="browser-grid-layout">
    <div class="browser-content">

      <template v-if="mode === 'index'">
        <input v-model="filterValue">
        <div class="performers-list">
          <div v-for="p in filteredPerformers"><a class="ajax-link" @click="openPerformer(p.id)">{{p.title}}</a></div>
        </div>
      </template>

      <template v-else-if="mode === 'performer'">
        <vue-performer :init-data="performer" :now-playing="$refs.player.nowPlaying ? $refs.player.nowPlaying.uid : null" @add="addTrack" @start="startSimplePlaying"></vue-performer>
      </template>

      <template v-else-if="mode === 'abyss'">
        <vue-abyss :id="abyssFolderId" @open="abyssFolderId = $event"></vue-abyss>
      </template>
    </div>

    <div class="queue-manager" v-if="tracklists.playlist.length > 0">
      <h3>Playlist:</h3>
      <table>
        <tr v-for="(track, trackIndex) in tracklists.playlist" class="queue-track" :class="track.origin" @click="$refs.player.playerStartPlaying(trackIndex)">
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
