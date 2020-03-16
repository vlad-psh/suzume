Vue.component('vue-rating-button', {
  props: {
    track: {type: Object, required: false},
  },
  data() {
    return {
      emoji: {'-1': '\u274c', 0: '\u2753', 1: '\ud83c\udfb5', 2: '\u2b50', 3: '\ud83d\udc96'},
      rating: null,
      popupOpened: false,
    }
  },
  computed: {
    currentRating() {
      return this.rating !== null ? this.rating : this.track.rating;
    },
    currentEmoji() {
      return this.emoji[this.currentRating] || '\u2754';
    },
    isAbyssTrack() {
      return this.track.md5 ? true : false;
    },
    availableRatings() {
      return this.isAbyssTrack ? [-1,0,1,2,3] : [0,1,2,3];
    },
  },
  methods: {
    saveRating(r) {
      const app = this;
      $.ajax({
        url: app.track.src,
        method: 'PATCH',
        data: {rating: r}
      }).done(data => {
        app.rating = r;
        console.log(JSON.parse(data));
      });
      app.popupOpened = false;
    },
  },
  template: `
<div class="vue-rating-button">
  <div @click="popupOpened = !popupOpened" class="emoji">{{currentEmoji}}</div>
  <div v-if="popupOpened" class="popup">
    <div v-for="r in availableRatings" class="rating emoji" @click="saveRating(r)">{{emoji[r]}}</div>
  </div>
</div>
`
});
