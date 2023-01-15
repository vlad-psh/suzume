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

    <div class="now-playing-info">
      <NuxtLink
        v-if="nowPlaying"
        :to="`/artist/${nowPlaying.artistId}`"
        class="thumbnail"
      >
        <img class="shadow" :src="nowPlaying.cover" />
        <img class="image" :src="nowPlaying.cover" />
      </NuxtLink>

      <div>
        <h2>{{ nowPlaying?.title }}</h2>
        <h3>{{ nowPlaying?.artist }}</h3>
      </div>
    </div>

    <div class="svg-icon player-button">
      <PauseIcon v-if="status === 'playing'" @click="pauseButtonClick" />
      <PlayIcon v-else @click="playButtonClick" />
    </div>

    <div
      ref="progressbarWrapper"
      class="player-progressbar-wrapper"
      @click="progressbarClick"
    >
      <svg preserveAspectRatio="none" viewBox="0 0 600 100" fill="currentColor">
        <mask id="waveform-mask">
          <path :d="waveformPath" fill="white" />
          <path d="M0 50 L600 50 Z" stroke="white" />
        </mask>
        <rect
          class="waveform-unfilled"
          :x="playerPosition * 6"
          y="0"
          width="600"
          height="100"
          mask="url(#waveform-mask)"
        />
        <rect
          class="waveform-filled"
          x="0"
          y="0"
          :width="playerPosition * 6 + 1"
          height="100"
          mask="url(#waveform-mask)"
        />
      </svg>
    </div>
  </div>
</template>

<script>
import PauseIcon from '@/assets/icons/player-pause.svg?inline'
import PlayIcon from '@/assets/icons/player-play.svg?inline'

export default {
  components: {
    PauseIcon,
    PlayIcon,
  },
  data() {
    return {
      status: 'init', // init, stopped, paused, playing
      playlist: [],
      nowPlayingIndex: null,
      playerPosition: 0, // in percents
      playerUpdater: null, // setInterval/clearInterval
      waveformPath: '',
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
      let percent = e.layerX / this.$refs.progressbarWrapper.clientWidth
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
      this.waveformPath = ''

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
        this.$refs.player.setAttribute(
          'src',
          `/download/audio/${this.nowPlaying.uid}`
        )
        this.$refs.player.play()
        this.status = 'playing'
        this.startUpdatingProgress()
        this.loadWaveform()
      } else {
        this.stopUpdatingProgress()
        this.playerPosition = 0
        this.status = 'stopped'
      }
    },
    async loadWaveform() {
      const resp = await this.$axios.get(
        `/download/waveform/${this.nowPlaying.uid}`
      )

      const points = resp.data
      const p = ['M0 50']
      for (let i = 0; i < points.length; i++) {
        p.push(`L${points[i][0]} ${points[i][1]}`)
      }

      this.waveformPath = p.join(' ') + ' Z'
    },
    startUpdatingProgress() {
      if (this.playerUpdater) return // Already has working updater
      if (!this.$refs.player.duration) return // Doesn't have metadata yet

      let interval = (
        (this.$refs.player.duration * 1000) /
        this.$refs.progressbarWrapper.clientWidth
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
  display: flex;
  align-items: center;
  justify-content: flex-start;
  padding: 0 0.8em;
  width: 100%;

  .now-playing-info {
    display: flex;
    padding: 0.5em 0;
    margin-right: 2em;
    gap: 1em;
    align-items: center;

    h2,
    h3 {
      margin: 0;
    }

    h2 {
      margin-top: -0.2em;
    }

    h3 {
      font-size: 1em;
      opacity: 0.6;
    }

    a.thumbnail {
      position: relative;

      img {
        border-radius: 0.3em;
        max-width: 3em;
        max-height: 3em;
        vertical-align: bottom;
      }

      img.image {
        position: relative;
      }

      img.shadow {
        filter: blur(0.5em);
        position: absolute;
        opacity: 0.5;
      }

      &:hover {
        img.image {
          transform: scale(102%);
        }
        img.shadow {
          filter: blur(0.7em);
          opacity: 0.7;
        }
      }
    }
  }

  .player-button {
    margin-right: 0.4em;
  }

  .svg-icon {
    display: inline-block;
    font-size: 2em;
    color: var(--text-color);
    border-radius: 100%;
    border: 2px solid #333;
    line-height: 1em;
    width: 1em;
    height: 1em;
    cursor: pointer;

    &:hover {
      background: var(--text-color);
      color: var(--text-color-inverted);
    }

    svg {
      width: 1em;
      height: 1em;
    }
  }

  .player-progressbar-wrapper {
    width: clamp(400px, 40vw, 600px);
    display: flex;
    align-items: center;
    height: 3em;
    padding: 0.3em 0;
    position: relative;
    cursor: text;

    svg {
      position: absolute;
      width: 100%;
      height: 3em;

      .waveform-filled {
        fill: var(--text-color);
      }
      .waveform-unfilled {
        fill: #7775;
      }
    }
  }

  &.vue-player-playing,
  &.vue-player-paused {
    .player-button {
      cursor: pointer;
    }
  }
} // end of .vue-player
</style>
