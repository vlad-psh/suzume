<template>
  <div class="release-cover">
    <a
      class="cover-link"
      :href="cover ? coverOrig : null"
      @click.prevent="openCover"
    >
      <div class="thumbnail">
        <img class="shadow" :src="coverThumb" />
        <img :src="coverThumb" />
      </div>
    </a>

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
      return this.cover
        ? `/download/image/${this.releaseId}/thumb`
        : '/cover.jpg'
    },
    coverOrig() {
      return `/download/image/${this.releaseId}/cover`
    },
  },
  methods: {
    openCover() {
      if (!this.cover) return
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
      display: flex;
      justify-content: flex-end;
      align-items: flex-start;
      height: 100px;
      width: 100px;
      position: relative;

      img {
        position: absolute;
        display: block;
        max-width: 100px;
        max-height: 100px;
        border-radius: 4px;
      }

      img.shadow {
        filter: blur(1em);
        transform: scale(90%);
      }

      &:hover img.shadow {
        transform: scale(95%);
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
