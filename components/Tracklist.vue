<template>
  <div class="tracks-table">
    <div
      v-for="track of existingTracks"
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
        :href="'/download/audio/' + track.uid"
        class="trackname"
        :title="track.title"
        @click.prevent="$emit('play', track.uid)"
        >{{ track.title }}</a
      >

      <div class="duration">{{ track.dur }}</div>
    </div>

    <div v-if="purgedTracks.length > 0" class="purged-tracks-expand-button">
      <div v-if="purgedTracksExpanded" @click="purgedTracksExpanded = false">
        Hide
      </div>
      <div v-else @click="purgedTracksExpanded = true">
        + {{ purgedTracks.length }} purged tracks
      </div>
    </div>

    <template v-if="purgedTracksExpanded">
      <div
        v-for="track of purgedTracks"
        :key="'track-' + track.uid"
        class="track-line track-purged"
      >
        <div class="rating">
          <RatingButton :track="track"></RatingButton>
        </div>

        <span class="trackname">{{ track.title }}</span>

        <div class="duration">{{ track.dur }}</div>
      </div>
    </template>
  </div>
</template>

<script>
export default {
  props: {
    tracks: { type: Array, required: true },
  },
  data() {
    return {
      purgedTracksExpanded: false,
    }
  },
  computed: {
    existingTracks() {
      return this.tracks.filter((track) => !track.purged)
    },
    purgedTracks() {
      return this.tracks.filter((track) => track.purged)
    },
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
    padding: 0 0.4em;
    border-radius: 0.25em;

    &:hover {
      background: #e5e5e5;
    }
    &.track-now-playing {
      background: #a3f797;
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
    padding: 0.25em 0;
    color: #333;

    &:hover {
      color: inherit;
    }
  }

  .duration {
    font-size: 0.8em;
  }
}

.purged-tracks-expand-button {
  font-size: 0.8em;
  opacity: 0.3;
  padding: 0.1em 0.8em;
  border-bottom-left-radius: 0.4em;
  border-bottom-right-radius: 0.4em;
  text-align: center;
  cursor: pointer;

  &:hover {
    background: #7773;
    opacity: 0.6;
  }
}
</style>
