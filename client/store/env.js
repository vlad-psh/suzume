export const state = () => ({
  user: null,
})

export const mutations = {
  SET_USER(state, val) {
    state.user = val
  },
}
