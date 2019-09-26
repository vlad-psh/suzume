Vue.component('vue-browser', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      performer: {},
      performers: [],
      player: null,
      playerStatus: 'init', // init, stopped, paused, playing
      playerUpdater: null, // setInterval/clearInterval
      playerPosition: 0, // in percents
      nowPlaying: null,
      playlist: [],
      upnext: [] // priority tracks
    }
  },
  methods: {
    loadPlaylist(tracks) {
      this.playlist = tracks;
      this.playerStartPlaying(true);
    },
    addUpnext(track) {
      track.origin = 'upnext';
      this.upnext.unshift(track);
      if (this.playerStopped()) this.playerStartPlaying(false);
    },
    playerStartPlaying(skipUpnext) {
      if (this.upnext.length > 0 || this.playlist.length > 0) {
        if (skipUpnext) {
          this.nowPlaying = this.playlist.length > 0 ? this.playlist.shift() : this.upnext.shift();
        } else {
          this.nowPlaying = this.upnext.length > 0 ? this.upnext.shift() : this.playlist.shift();
        }
        this.nowPlaying.origin = "np";
        this.player.setAttribute('src', this.nowPlaying.src);
        this.player.play();
        this.playerStatus = 'playing';
        if (!this.playerUpdater) {
          this.playerUpdater = setInterval(() => {
            this.playerPosition = Math.round(this.player.currentTime / this.player.duration * 1000)/10;
          }, 500);
        }
      } else {
        clearInterval(this.playerUpdater);
        this.playerUpdater = null;
        this.playerPosition = 0;

        this.nowPlaying = null;
        this.playerStatus = 'stopped';
      }
    },
    openIndex() {
      $.ajax({
        url: `/api/index`,
        method: 'GET'
      }).done(data => {
        this.performer = {};
        this.performers = JSON.parse(data);
      });
    },
    openPerformer(id) {
      $.ajax({
        url: `/api/performer/${id}`,
        method: 'GET'
      }).done(data => {
        this.performers = [];
        this.performer = JSON.parse(data);
      });
    },
    playerStopped() {
      return this.player.src === '' || this.player.ended === true;
    },
    progressbarClick(e) {
      if (this.playerStatus !== 'playing' && this.playerStatus !== 'paused') return;
      var percent = (e.pageX - e.srcElement.offsetLeft) / e.srcElement.clientWidth;
      percent = percent > 1 ? 1 : (percent < 0 ? 0 : percent); // return value between 0 and 1
      console.log(percent);
      this.player.currentTime = this.player.duration * percent;
    },
    pauseButtonClick() {
      this.player.pause();
      this.playerStatus = 'paused';
    },
    playButtonClick() {
      if (this.playerStatus !== 'paused') return;
      this.player.play();
      this.playerStatus = 'playing';
    }
  }, // end of methods()
  computed: {
    allTracks() {
      tracks = [];
      if (this.nowPlaying) tracks.push(this.nowPlaying);
      if (this.upnext.length > 0) tracks.push(...this.upnext);
      if (this.playlist.length > 0) tracks.push(...this.playlist);
      return tracks;
    }
  },
  created() {
    if (this.initData.performer) this.performer = this.initData.performer;
    if (this.initData.performers) this.performers = this.initData.performers;
  },
  mounted() {
    this.player = $('#main-player2')[0];
  },
  template: `
<div class="vue-browser">
  <a class="ajax-link" @click="openIndex">Index</a>
  <br>
  <audio id="main-player2" preload="none" @ended="playerStartPlaying(false)" controls="controls" style="width: 500px"></audio>

  <div class="vue-player" :class="'vue-player-' + playerStatus">
    <template>
      <div v-if="playerStatus === 'paused'" class="player-button" @click="playButtonClick">&#x25b6;</div>
      <div v-else-if="playerStatus === 'playing'" class="player-button" @click="pauseButtonClick">&#x23f8;</div>
      <div v-else class="player-button">&#x25b6;</div>
    </template>
    <div class="player-progressbar-wrapper" @click="progressbarClick">
      <div class="player-progressbar">
        <div class="player-progressbar-knob" :style="'left: calc(' + playerPosition + '% - 4px);'"></div>
      </div>
    </div>
  </div>

  <ul v-if="performers.length > 0" class="performers-list">
    <li v-for="p in performers"><a class="ajax-link" @click="openPerformer(p.id)">{{p.title}}</a></li>
  </ul>

  <table v-if="performer.id"><tr><td>
  <vue-performer :init-data="performer" :now-playing="nowPlaying ? nowPlaying.uid : null" @load-playlist="loadPlaylist($event)" @upnext="addUpnext($event)"></vue-performer>
  </td><td>
    <div class="queue-manager">
      <h3>Queue:</h3>
      <table>
        <tr v-for="track in allTracks" class="queue-track" :class="track.origin">
          <td>
            <template v-if="track.origin === 'np' && playerStatus === 'playing'">
              <div v-for="bar in [1,2,3,4]" class="eq-bar"></div>
            </template>
            <template v-else>{{track.rating}}</template>
          </td>
          <td>{{track.title}}<br><span class="performer">{{track.performer}}</span></td>
        </tr>
      </table>
    </div>
  </td></tr></table>
</div>
`
});
