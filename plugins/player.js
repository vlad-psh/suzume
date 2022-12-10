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
      startPlaylist(playlist, uid) {
        if (!this.mPlayer) return

        playlist = playlist
          .filter((i) => !i.purged)
          .map((i) => this.trackObject(i))

        this.mPlayer.startPlaylist(playlist, uid)
      },
      trackObject(track) {
        return {
          uid: track.uid,
          title: track.title,
          artist: this.title,
          rating: track.rating,
          src: `/download/audio/${track.uid}`,
        }
      },
    },
  })
  inject('player', player)
}
