export default async (context, inject) => {
  const { store, $axios, next } = context
  inject('auth', {
    async getSession() {
      if (store.state.env.user || store.state.env.user === false) return
      try {
        const resp = await $axios.get('/api/session')
        store.commit('env/SET_USER', resp.data)
      } catch {
        store.commit('env/SET_USER', false)
      }
    },
    async logout() {
      try {
        await $axios.delete('/api/session')
        store.commit('env/SET_USER', null)
      } catch {}
      next('/login')
    },
    async login({ username, password }) {
      try {
        const resp = await $axios.post('/api/session', {
          username,
          password,
        })
        store.commit('env/SET_USER', resp.data)
      } catch {}
      next('/')
    },
    loggedIn() {
      return !!store.state.env.user
    },
  })
  await context.$auth.getSession()
}
