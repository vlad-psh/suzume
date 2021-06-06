<template>
  <div class="main-menu">
    <template v-if="$store.state.env.user">
      <NuxtLink to="/">Index</NuxtLink>
      <NuxtLink to="/abyss">Abyss</NuxtLink>
      {{ $store.state.env.user.username }}
      <a @click="$auth.logout">logout</a>
      <MediaPlayer></MediaPlayer>
    </template>
    <template v-else>
      <NuxtLink to="/login">login</NuxtLink>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.main-menu {
  position: fixed;
  top: 0;
  z-index: 100;
}
</style>
