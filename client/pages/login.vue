<template>
  <div class="middle-content login-form">
    <h2>Login</h2>
    <form>
      <input v-model="username" type="text" placeholder="Username" />
      <input v-model="password" type="password" placeholder="Password" />
      <input type="submit" value="Login" @click.prevent="submit" />
    </form>
  </div>
</template>

<script>
export default {
  data() {
    return {
      username: null,
      password: null,
    }
  },
  methods: {
    submit() {
      this.$auth.login({
        username: this.username,
        password: this.password,
      })
    },
  },
}
</script>
