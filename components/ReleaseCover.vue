<template>
  <div class="release-cover">
    <template v-if="cover">
      <a class="cover-link" :href="coverOrig" @click.prevent="openCover"
        ><div class="thumbnail"><img :src="coverThumb" /></div
      ></a>
    </template>
    <template v-else><div class="thumbnail"></div></template>

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
    cover: { type: String, default: null },
    releaseId: { type: String, required: true },
  },
  computed: {
    coverThumb() {
      return `/download/image/${this.releaseId}/thumb`
    },
    coverOrig() {
      return `/download/image/${this.releaseId}/cover`
    },
  },
  methods: {
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
}

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
}
</style>
