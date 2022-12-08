<template>
  <table class="tracks-table">
    <tbody>
      <tr
        v-for="track of tracks"
        :key="'track-' + track.uid"
        class="track-line"
      >
        <td class="rating">
          <RatingButton :track="track"></RatingButton>
        </td>
        <td
          class="trackname"
          :class="
            $player.nowPlaying.uid == track.uid ? 'track-now-playing' : null
          "
        >
          <a
            :href="'/download/audio/' + track.uid"
            @click.prevent="$emit('play', track.uid)"
            >{{ track.title }}</a
          >
        </td>
        <td class="duration">{{ track.dur }}</td>
      </tr>
    </tbody>
  </table>
</template>

<script>
export default {
  props: {
    tracks: { type: Array, required: true },
  },
}
</script>

<style lang="scss" scoped>
.tracks-table {
  .trackname.track-now-playing {
    background: #ffffa3;
  }

  .duration {
    font-size: 0.8em;
  }
}
</style>
