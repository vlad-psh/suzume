<template>
  <div class="tracks-table">
    <div
      v-for="track of tracks"
      :key="'track-' + track.uid"
      class="track-line"
      :class="{
        'track-now-playing': $player.nowPlaying.uid == track.uid,
        'track-purged': track.purged,
      }"
    >
      <div class="rating">
        <RatingButton :track="track"></RatingButton>
      </div>

      <a
        v-if="!track.purged"
        :href="'/download/audio/' + track.uid"
        class="trackname"
        :title="track.title"
        @click.prevent="$emit('play', track.uid)"
        >{{ track.title }}</a
      >
      <span v-else class="trackname">{{ track.title }}</span>

      <div class="duration">{{ track.dur }}</div>
    </div>
  </div>
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
  max-width: 20em;

  .track-line {
    display: flex;
    justify-content: space-around;
    align-items: center;
    gap: 0.5em;
    min-height: 1.7em;

    &.track-now-playing {
      background: #ffffa3;
    }
    &.track-purged {
      opacity: 0.3;
    }
  }

  .trackname {
    flex-grow: 100;
    text-decoration: none;
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
  }

  .duration {
    font-size: 0.8em;
  }
}
</style>
