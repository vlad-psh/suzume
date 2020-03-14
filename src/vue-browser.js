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
      player: null,
      playerStatus: 'init', // init, stopped, paused, playing
      playerUpdater: null, // setInterval/clearInterval
      playerPosition: 0, // in percents
      nowPlayingIndex: null,
      playlist: [],
      abyssFolderId: 0,
    }
  },
  methods: {
    addTrack(track) {
      this.playlist.push(track);
      if (this.playerStatus === 'init' || this.playerStatus === 'stopped') {
        this.playerStartPlaying(this.playlist.length - 1);
      }
    },
    playerStartPlaying(index = null) {
      //if (this.playerStatus === 'playing' && this.nowPlayingIndex === index) return;

      if (index === null) {
        if (this.nowPlayingIndex !== null) {
          index = this.nowPlayingIndex + 1;
          if (index >= this.playlist.length) index = 0;
          // TODO: check if repeat mode is turned on
          // If repeat mode is turned off, set 'index = null'
        } else {
          index = 0;
        }
      }

      this.nowPlayingIndex = index;
      if (index !== null) {
        this.playerPosition = 0;
        this.player.setAttribute('src', this.nowPlaying.src);
        this.player.play();
        this.playerStatus = 'playing';
        this.startUpdatingProgress();
      } else {
        this.stopUpdatingProgress();
        this.playerPosition = 0;
        this.playerStatus = 'stopped';
      }
    },
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
    playerStopped() {
      return this.player.src === '' || this.player.ended === true;
    },
    progressbarClick(e) {
      if (this.playerStatus !== 'playing' && this.playerStatus !== 'paused') return;
      var leftOffset = e.srcElement.offsetLeft + document.querySelectorAll('.vue-player')[0].offsetLeft;
      var percent = (e.pageX - leftOffset) / e.srcElement.clientWidth;
      percent = percent > 1 ? 1 : (percent < 0 ? 0 : percent); // return value between 0 and 1
      this.player.currentTime = this.player.duration * percent;
      this.playerPosition = (percent * 100).toFixed(1);
    },
    pauseButtonClick() {
      this.player.pause();
      this.playerStatus = 'paused';
      this.stopUpdatingProgress();
    },
    playButtonClick() {
      if (this.playerStatus !== 'paused') return;
      this.player.play();
      this.playerStatus = 'playing';
      this.startUpdatingProgress();
    },
    startUpdatingProgress() {
      if (this.playerUpdater) return; // Already has working updater
      if (!this.player.duration) return; // Doesn't have metadata yet

      var progressbarWidth = document.querySelectorAll('.vue-player .player-progressbar-wrapper')[0].clientWidth;
      var interval = (this.player.duration * 1000 / progressbarWidth).toFixed(0);
      if (interval < 200) interval = 200;

      this.playerUpdater = setInterval(() => {
        this.playerPosition = (this.player.currentTime / this.player.duration * 100).toFixed(1);
      }, interval);
    },
    stopUpdatingProgress() {
      clearInterval(this.playerUpdater);
      this.playerUpdater = null;
    },
    playerLoadedMetadata() {
      if (this.playerStatus === 'playing') {
        this.stopUpdatingProgress();
        this.startUpdatingProgress();
      }
    },
  }, // end of methods()
  computed: {
    nowPlaying() {
      return this.nowPlayingIndex !== null ? this.playlist[this.nowPlayingIndex] : null;
    },
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
    this.player = document.querySelectorAll('#main-player')[0];
  },
  template: `
<div class="vue-browser">
  <audio id="main-player" preload="none" @ended="playerStartPlaying()" controls="controls" style="display: none;" @loadedmetadata="playerLoadedMetadata"></audio>

  <div class="vue-player" :class="'vue-player-' + playerStatus">
    <a class="ajax-link" @click="mode = 'index'">Index</a>
    <a class="ajax-link" @click="mode = 'abyss'">Abyss</a>
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

  <div class="browser-grid-layout">
    <div class="browser-content">

      <template v-if="mode === 'index'">
        <input v-model="filterValue">
        <div class="performers-list">
          <div v-for="p in filteredPerformers"><a class="ajax-link" @click="openPerformer(p.id)">{{p.title}}</a></div>
        </div>
      </template>

      <template v-else-if="mode === 'performer'">
        <vue-performer :init-data="performer" :now-playing="nowPlaying ? nowPlaying.uid : null" @play-track="addTrack($event)"></vue-performer>
      </template>

      <template v-else-if="mode === 'abyss'">
        <vue-abyss :id="abyssFolderId" @open="abyssFolderId = $event"></vue-abyss>
      </template>
    </div>

    <div class="queue-manager">
      <h3>Queue:</h3>
      <table>
        <tr v-for="(track, trackIndex) in playlist" class="queue-track" :class="track.origin" @click="playerStartPlaying(trackIndex)">
          <td>
            <template v-if="trackIndex === nowPlayingIndex && playerStatus === 'playing'">
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
