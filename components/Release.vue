<template>
  <div v-if="tracks.length > 0" class="vue-release">
    <div class="release-cover">
      <template v-if="cover">
        <a class="cover-link" :href="coverOrig"
          ><div class="thumbnail"><img :src="coverThumb" /></div
        ></a>
      </template>
      <template v-else><div class="thumbnail"></div></template>
    </div>
    <div class="release-content">
      <span class="release-title"
        >{{ year }} {{ title }}
        <span style="font-size: 0.65em; opacity: 0.4; font-weight: normal"
          >#{{ id }}</span
        >
      </span>
      <table class="tracks-table">
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
            :class="nowPlaying == track.uid ? 'track-now-playing' : null"
          >
            <a
              :href="'download/audio/' + track.uid"
              @click.prevent="playTrack(track.uid)"
              >{{ track.title }}</a
            >
          </td>
          <td class="duration">{{ track.dur }}</td>
        </tr>
      </table>
      <div style="font-size: 0.8em; opacity: 0.7">
        <a
          v-for="f in folders"
          :key="'folder-link-' + f"
          style="margin-right: 0.5em"
          @click="openAbyss(f)"
          >{{ f }}</a
        >
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    payload: { type: Object, required: true },
    nowPlaying: { type: String, default: null },
  },
  data() {
    return {
      id: null,
      title: null,
      year: null,
      tracks: [],
      folders: [],
      cover: null,
    }
  },
  computed: {
    coverThumb() {
      return `/download/image/${this.id}/thumb`
    },
    coverOrig() {
      return `/download/image/${this.id}/cover`
    },
  },
  created() {
    for (const key of Object.keys(this.payload)) {
      this[key] = this.payload[key]
    }
  },
}
</script>

<style lang="scss" scoped>
.vue-release {
  width: 16em;
  padding: 1em;

  .release-cover {
    text-align: left;

    a.cover-link {
      display: inline-block;

      .thumbnail {
        height: 100px;
        max-width: 100px;
        display: table-cell;
        vertical-align: bottom;

        img {
          display: block;
          max-width: 100px;
          max-height: 100px;
          border-radius: 4px;
        }
      }
    }
  } // end of .release-cover

  .release-content {
    width: 100%;
    .tracks-table {
      //border-collapse: collapse;
      border-spacing: 1px;
      width: 100%;

      td {
        vertical-align: middle;
      }
      td.trackname {
        width: 100%;
        max-width: 11em;
        position: relative;
        z-index: 10;
        cursor: pointer;
        height: 1.6em;

        span {
          display: block;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          color: #1c79cb;
        }
        &:hover span {
          width: inline;
          display: initial;
          color: #529fe2;
          text-shadow: 1px 1px 0 white;
          background: rgba(255, 255, 255, 0.7);
        }
        &.track-now-playing,
        &.track-now-playing span {
          background: #ffffa3;
        }
      } // end of td.trackname
      td.duration {
        font-size: 0.8em;
      }
    } // end of .tracks-table
  } // end of .release-content
} // end of .vue-release
</style>
