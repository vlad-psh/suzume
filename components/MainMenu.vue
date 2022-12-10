<template>
  <div class="main-menu">
    <template v-if="$store.state.env.user">
      <div class="navigation-row">
        <NuxtLink to="/">Index</NuxtLink>
        <NuxtLink to="/abyss">Abyss</NuxtLink>
        <div class="spacer"></div>
        {{ $store.state.env.user.username }}
        <a @click="$auth.logout">Logout</a>
      </div>

      <div class="player-row">
        <MediaPlayer />
      </div>
    </template>
    <template v-else>
      <div class="spacer"></div>
      <NuxtLink to="/login">Login</NuxtLink>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.main-menu {
  position: fixed;
  top: 0;
  z-index: 100;
  background: #a72734;
  color: white;
  width: 100%;

  .navigation-row {
    font-size: 0.8em;
  }

  .navigation-row,
  .player-row {
    display: flex;
    align-items: baseline;
    width: 100%;
  }

  a {
    color: white;
    padding: 0.5em 0.7em;
    display: inline-block;
    text-decoration: none;

    &:hover {
      background: #c53342;
    }
  }

  .spacer {
    flex-grow: 1;
  }
}
</style>
