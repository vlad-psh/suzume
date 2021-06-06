import Vue from 'vue'

export default (context, inject) => {
  const player = new Vue({
    data() {
      return {
        mPlayer: null,
      }
    },
    computed: {
      nowPlaying() {
        return this.mPlayer && this.mPlayer.nowPlaying
          ? this.mPlayer.nowPlaying
          : {}
      },
    },
    methods: {
      startPlaylist(playlist) {
        if (this.mPlayer) this.mPlayer.startPlaylist(playlist)
      },
    },
  })
  inject('player', player)
}
