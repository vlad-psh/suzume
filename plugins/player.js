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
      // 'artist' object is expected to contain 'releases' array,
      // which in turn, should contain 'tracks' array
      playArtist(artist, uid) {
        if (!this.mPlayer) return

        const playlist = []

        for (const release of artist.releases) {
          playlist.push(
            ...release.tracks
              .filter((track) => !track.purged)
              .map((track) => this.trackObject(track, release, artist))
          )
        }

        this.mPlayer.startPlaylist(playlist, uid)
      },
      trackObject(track, release, artist) {
        return {
          uid: track.uid,
          title: track.title,
          rating: track.rating,
          artist: artist.title,
          artistId: artist.id,
          release: release.title,
          cover: release.cover
            ? `/download/image/${release.id}/thumb`
            : '/cover.jpg',
        }
      },
    },
  })
  inject('player', player)
}
