Vue.component('vue-rating-button', {
  props: {
    track: {type: Object, required: false},
  },
  data() {
    return {
// to get \u sequence, use '@'.charAt(0/1) in web console
      emoji: {'-2': '\ud83e\uddfc', '-1': '\u274c', 0: '\ud83c\udf38', 1: '\ud83c\udfb5', 2: '\u2b50', 3: '\ud83d\udc96'},
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
  },
  methods: {
    saveRating(r) {
      const app = this;
      $.ajax({
        url: "/api/rating/" + app.track.uid,
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
    <div v-for="r in [-2,-1,0,1,2,3]" class="rating emoji" @click="saveRating(r)">{{emoji[r]}}</div>
  </div>
</div>
`
});
