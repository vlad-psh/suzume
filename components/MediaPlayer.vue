<template>
  <div class="vue-player" :class="'vue-player-' + status">
    <audio
      id="main-player"
      ref="player"
      preload="none"
      controls="controls"
      style="display: none"
      @ended="playerStartPlaying()"
      @loadedmetadata="playerLoadedMetadata"
      @error="playerError()"
    ></audio>

    <div
      v-if="status === 'paused'"
      class="player-button"
      @click="playButtonClick"
    >
      ▶️
    </div>
    <div
      v-else-if="status === 'playing'"
      class="player-button"
      @click="pauseButtonClick"
    >
      ⏸️
    </div>
    <div v-else class="player-button">⏹️</div>

    <div class="player-progressbar-wrapper" @click="progressbarClick">
      <div class="player-progressbar">
        <div
          class="player-progressbar-knob"
          :style="'left: calc(' + playerPosition + '% - 4px);'"
        ></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      status: 'init', // init, stopped, paused, playing
      playlist: [],
      nowPlayingIndex: null,
      playerPosition: 0, // in percents
      playerUpdater: null, // setInterval/clearInterval
    }
  },
  computed: {
    nowPlaying() {
      return this.nowPlayingIndex !== null
        ? this.playlist[this.nowPlayingIndex]
        : null
    },
  },
  mounted() {
    this.$player.mPlayer = this
  },
  methods: {
    addTrack(track) {
      this.playlist.push(track)
      if (this.status === 'init' || this.status === 'stopped') {
        this.playerStartPlaying(this.playlist.length - 1)
      }
    },
    startPlaylist(playlist, uid) {
      const idx = playlist.findIndex((i) => i.uid === uid)
      this.playlist = playlist
      this.playerStartPlaying(idx)
    },
    playButtonClick() {
      if (this.status !== 'paused') return
      this.$refs.player.play()
      this.status = 'playing'
      this.startUpdatingProgress()
    },
    pauseButtonClick() {
      this.$refs.player.pause()
      this.status = 'paused'
      this.stopUpdatingProgress()
    },
    progressbarClick(e) {
      if (this.status !== 'playing' && this.status !== 'paused') return
      const leftOffset = e.srcElement.getBoundingClientRect().x
      let percent = (e.pageX - leftOffset) / e.srcElement.clientWidth
      percent = percent > 1 ? 1 : percent < 0 ? 0 : percent // return value between 0 and 1
      this.$refs.player.currentTime = this.$refs.player.duration * percent
      this.playerPosition = (percent * 100).toFixed(1)
    },
    playerLoadedMetadata() {
      if (this.status === 'playing') {
        this.stopUpdatingProgress()
        this.startUpdatingProgress()
      }
    },
    playerError(e) {
      this.playerStartPlaying()
    },
    playerStartPlaying(index = null) {
      // if (this.status === 'playing' && this.nowPlayingIndex === index) return;

      if (index === null) {
        if (this.nowPlayingIndex !== null) {
          index = this.nowPlayingIndex + 1
          if (index >= this.playlist.length) index = 0
          // TODO: check if repeat mode is turned on
          // If repeat mode is turned off, set 'index = null'
        } else {
          index = 0
        }
      }

      this.nowPlayingIndex = index
      if (index !== null) {
        this.playerPosition = 0
        this.$refs.player.setAttribute('src', this.nowPlaying.src)
        this.$refs.player.play()
        this.status = 'playing'
        this.startUpdatingProgress()
      } else {
        this.stopUpdatingProgress()
        this.playerPosition = 0
        this.status = 'stopped'
      }
    },
    startUpdatingProgress() {
      if (this.playerUpdater) return // Already has working updater
      if (!this.$refs.player.duration) return // Doesn't have metadata yet

      const progressbarWidth = document.querySelectorAll(
        '.vue-player .player-progressbar-wrapper'
      )[0].clientWidth
      let interval = (
        (this.$refs.player.duration * 1000) /
        progressbarWidth
      ).toFixed(0)
      if (interval < 200) interval = 200

      this.playerUpdater = setInterval(() => {
        if (typeof this.$refs.player === 'undefined') {
          // controller were destroyed
          this.stopUpdatingProgress()
          return
        }

        this.playerPosition = (
          (this.$refs.player.currentTime / this.$refs.player.duration) *
          100
        ).toFixed(1)
      }, interval)
    },
    stopUpdatingProgress() {
      clearInterval(this.playerUpdater)
      this.playerUpdater = null
    },
  },
}
</script>

<style lang="scss" scoped>
.vue-player {
  width: 400px;
  display: flex;
  align-items: center;
  padding: 0.2em 0.8em;

  &:hover {
    background: #c53342;
  }

  div {
    display: inline-block;
  }

  .player-button {
    padding: 0.2em 0.4em;
    margin-right: 0.4em;
    width: 1.2em;
    // default (for init/stopped states)
    cursor: default;
  }

  .player-progressbar-wrapper {
    width: 100%;
    display: flex;
    align-items: center;
    height: 2em;

    .player-progressbar {
      position: relative;
      display: flex;
      align-items: center;
      width: 100%;
      height: 3px;
      background: #fff;

      .player-progressbar-knob {
        position: absolute;
        height: 9px;
        width: 9px;
        border-radius: 50%;
        background-color: #fff;
        box-sizing: border-box;
      }
    } // end of .player-progressbar
  } // end of .player-progressbar-wrapper

  &.vue-player-playing,
  &.vue-player-paused {
    .player-button {
      cursor: pointer;
    }
    .player-progressbar-wrapper:hover .player-progressbar-knob,
    .player-progressbar-wrapper:hover .player-progressbar-knob {
      background-color: #a72734;
      border: 2px solid white;
    }
  }
} // end of .vue-player
</style>
