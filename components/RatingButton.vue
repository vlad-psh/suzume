<template>
  <div class="vue-rating-button">
    <Popper ref="popper" trigger="clickToToggle">
      <div class="popper">
        <div
          v-for="r in [-2, -1, 0, 1, 2, 3]"
          :key="'rating-button-' + r"
          class="emoji-item"
          :class="{ current: currentRating === r }"
          @click="saveRating(r)"
        >
          {{ emoji[r] }}
        </div>
      </div>
      <span slot="reference" class="rating-button">{{ currentEmoji }}</span>
    </Popper>
  </div>
</template>

<script>
import Popper from 'vue-popperjs'
import 'vue-popperjs/dist/vue-popper.css'

export default {
  components: { Popper },
  props: {
    track: { type: Object, required: true },
  },
  data() {
    return {
      // to get \u sequence, use '@'.charAt(0/1) in web console
      emoji: {
        '-2': '\uD83E\uDDFC',
        '-1': '\u274C',
        0: '\uD83C\uDF38',
        1: '\uD83C\uDFB5',
        2: '\u2B50',
        3: '\uD83D\uDC96',
      },
      rating: null,
      popupOpened: false,
    }
  },
  computed: {
    currentRating() {
      return this.rating !== null ? this.rating : this.track.rating
    },
    currentEmoji() {
      return this.emoji[this.currentRating] || '\u2754'
    },
  },
  methods: {
    async saveRating(r) {
      await this.$axios.patch(`/api/rating/${this.track.uid}`, {
        rating: r,
      })

      this.rating = r
      this.$refs.popper.doClose()
    },
  },
}
</script>

<style lang="scss" scoped>
.vue-rating-button {
  .rating-button {
    cursor: pointer;
  }
}

body .popper {
  background-color: #fff;
  box-shadow: #555 0 0 100px 0;
  padding: 0;
  border-radius: 0.5em;
  border: none;
  padding: 0.4em 0.6em;
  display: flex;

  .popper__arrow {
    border: none;
    width: 25px;
    height: 11px;
    background-color: white;
    mask-image: url('assets/icons/popover-arrow.svg');
    mask-size: 25px 11px;
  }

  &[x-placement^='bottom'] {
    margin-top: 12px;
    .popper__arrow {
      top: -10.5px;
    }
  }
  &[x-placement^='top'] {
    margin-bottom: 12px;
    .popper__arrow {
      bottom: -10.5px;
      transform: rotate(180deg);
    }
  }

  .emoji-item {
    padding: 0.4em;
    cursor: pointer;
    border-radius: 0.2em;
    border: 1px solid transparent;
    margin: 0 0.5px;

    &:hover {
      border: 1px dashed #7779;
    }
    &.current {
      background: #7773;
    }
  }
}
</style>
