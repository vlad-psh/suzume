Vue.component('vue-player', {
  props: {
    initData: {type: Object, required: false}
  },
  data() {
    return {
      playerStatus: 'init', // init, stopped, paused, playing
      playerUpdater: null, // setInterval/clearInterval
      playerPosition: 0, // in percents
      nowPlayingIndex: null,
      playlist: [],
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
        this.$refs.player.setAttribute('src', this.nowPlaying.src);
        this.$refs.player.play();
        this.playerStatus = 'playing';
        this.startUpdatingProgress();
      } else {
        this.stopUpdatingProgress();
        this.playerPosition = 0;
        this.playerStatus = 'stopped';
      }
    },
    playerStopped() {
      return this.$refs.player.src === '' || this.$refs.player.ended === true;
    },
    progressbarClick(e) {
      if (this.playerStatus !== 'playing' && this.playerStatus !== 'paused') return;
      var leftOffset = e.srcElement.offsetLeft + document.querySelectorAll('.vue-player')[0].offsetLeft;
      var percent = (e.pageX - leftOffset) / e.srcElement.clientWidth;
      percent = percent > 1 ? 1 : (percent < 0 ? 0 : percent); // return value between 0 and 1
      this.$refs.player.currentTime = this.$refs.player.duration * percent;
      this.playerPosition = (percent * 100).toFixed(1);
    },
    pauseButtonClick() {
      this.$refs.player.pause();
      this.playerStatus = 'paused';
      this.stopUpdatingProgress();
    },
    playButtonClick() {
      if (this.playerStatus !== 'paused') return;
      this.$refs.player.play();
      this.playerStatus = 'playing';
      this.startUpdatingProgress();
    },
    startUpdatingProgress() {
      if (this.playerUpdater) return; // Already has working updater
      if (!this.$refs.player.duration) return; // Doesn't have metadata yet

      var progressbarWidth = document.querySelectorAll('.vue-player .player-progressbar-wrapper')[0].clientWidth;
      var interval = (this.$refs.player.duration * 1000 / progressbarWidth).toFixed(0);
      if (interval < 200) interval = 200;

      this.playerUpdater = setInterval(() => {
        this.playerPosition = (this.$refs.player.currentTime / this.$refs.player.duration * 100).toFixed(1);
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
  },
  template: `
<div class="vue-player" :class="'vue-player-' + playerStatus">
  <audio id="main-player" ref="player" preload="none" @ended="playerStartPlaying()" controls="controls" style="display: none;" @loadedmetadata="playerLoadedMetadata"></audio>

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
`
});
