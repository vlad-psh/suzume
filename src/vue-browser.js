Vue.component('vue-browser', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      mode: 'index',
      artist: {},
      artists: [],
      filterValue: '',
      abyssFolderId: 0,
      tracklists: {playlist: [], simple: []},
    }
  },
  methods: {
    reloadCurrent() {
      if (this.mode === 'index') {
        this.reloadIndex();
      } else if (this.mode === 'artist') {
        this.mode = 'index';
        this.openArtist(this.artist.id);
      }
    },
    reloadIndex() {
      $.ajax({
        url: `/api/index`,
        method: 'GET'
      }).done(data => {
        this.artists = JSON.parse(data);
      });
    },
    openArtist(id) {
      $.ajax({
        url: `/api/artist/${id}`,
        method: 'GET'
      }).done(data => {
        this.artist = JSON.parse(data);
        this.mode = 'artist';
      });
    },
    openAbyss(id) {
      this.abyssFolderId = id;
      this.mode = 'abyss';
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
    filteredArtists() {
      if (this.filterValue) {
        var r = new RegExp(this.filterValue, 'i');
        return this.artists.filter(i => i.title.match(r) || (i.aliases && i.aliases.match(r)));
      } else {
        return this.artists;
      }
    }
  },
  created() {
    if (this.initData.artist) this.artist = this.initData.artist;
    if (this.initData.artists) this.artists = this.initData.artists;
  },
  mounted() {
  },
  template: `
<div class="vue-browser">
  <vue-player ref="player" :tracklists="tracklists"></vue-player>

  <div class="menu" style="position: fixed; top: 0; left: 0; background: white;">
    <a class="ajax-link" @click="mode = 'index'">Index</a>
    <a class="ajax-link" @click="mode = 'abyss'">Abyss</a>
    <a class="ajax-link" @click="reloadCurrent">Refresh content</a>
  </div>


  <div class="browser-grid-layout">
    <div class="browser-content">

      <template v-if="mode === 'index'">
        <input v-model="filterValue">
        <div class="artists-list">
          <div v-for="a in filteredArtists"><a class="ajax-link" @click="openArtist(a.id)">{{a.title}}</a></div>
        </div>
      </template>

      <template v-else-if="mode === 'artist'">
        <vue-artist :init-data="artist" :now-playing="$refs.player.nowPlaying ? $refs.player.nowPlaying.uid : null" @add="addTrack" @start="startSimplePlaying" @abyss="openAbyss"></vue-artist>
      </template>

      <template v-else-if="mode === 'abyss'">
        <vue-abyss :id="abyssFolderId" :now-playing="$refs.player.nowPlaying ? $refs.player.nowPlaying.md5 || $refs.player.nowPlaying.uid : null" @open="abyssFolderId = $event" @start="startSimplePlaying"></vue-abyss>
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
          <td>{{track.title}}<br><span class="artist">{{track.artist}}</span></td>
        </tr>
      </table>
    </div>
  </div>
</div>
`
});
