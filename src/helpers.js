export default {
  compare(a, b, reverse = false) {
    return a > b ? (reverse ? -1 : 1) : (a < b ? (reverse ? 1 : -1) : 0);
  },
  ratingEmoji(rating) {
    // 274c, 2753, 1f3b5, 2b50, 1f496
    return ['\u274c', '\u2753', '\ud83c\udfb5', '\u2b50', '\ud83d\udc96'][rating];
  },
  splitArray(arr, idx) {
    return [].concat(arr.slice(idx, arr.length), idx !== 0 ? arr.slice(0, idx): []);
  },
}

