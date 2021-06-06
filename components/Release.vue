<template>
  <div v-if="tracks.length > 0" class="vue-release">
    <div class="release-cover">
      <template v-if="cover">
        <a class="cover-link" :href="coverOrig" @click.prevent="openCover"
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
                @click.prevent="playTrack(track.uid)"
                >{{ track.title }}</a
              >
            </td>
            <td class="duration">{{ track.dur }}</td>
          </tr>
        </tbody>
      </table>
      <div style="font-size: 0.8em; opacity: 0.7">
        <NuxtLink
          v-for="f in folders"
          :key="'folder-link-' + f"
          :to="'/abyss/' + f"
          style="margin-right: 0.5em"
        >
          {{ f }}
        </NuxtLink>
      </div>
    </div>

    <div
      id="fullscreen-cover-container"
      ref="fullscreenContainer"
      @click="closeCover"
    >
      <div id="fullscreen-cover-flexbox"><img :src="coverOrig" /></div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    payload: { type: Object, required: true },
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
  methods: {
    playTrack(uid) {
      this.$emit('play', uid)
    },
    openCover() {
      this.$refs.fullscreenContainer.style.display = 'block'
    },
    closeCover() {
      this.$refs.fullscreenContainer.style.display = 'none'
    },
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

#fullscreen-cover-container {
  display: none;
  position: fixed;
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  top: 0;
  left: 0;
  background-color: rgba(0, 0, 0, 0.85);
  z-index: 500;
  cursor: pointer;

  #fullscreen-cover-flexbox {
    display: flex;
    flex-flow: row wrap;
    width: 100%;
    height: 100%;
    justify-content: center;
    align-items: center;

    img {
      max-height: 100%;
      max-width: 100%;
    }
  }
} // end of #fullscreen-cover-container
</style>
