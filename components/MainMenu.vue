<template>
  <div class="main-menu">
    <div class="navigation">
      <template v-if="$store.state.env.user">
        <NuxtLink to="/">Index</NuxtLink>
        <NuxtLink to="/abyss">Abyss</NuxtLink>
        <div class="spacer"></div>
        {{ $store.state.env.user.username }}
        <a @click="$auth.logout">Logout</a>
      </template>
      <template v-else>
        <div class="spacer"></div>
        <NuxtLink to="/login">Login</NuxtLink>
      </template>
    </div>

    <MediaPlayer v-if="$store.state.env.user" />
  </div>
</template>

<style lang="scss" scoped>
.main-menu {
  width: 100%;
  position: fixed;
  top: 0;
  z-index: 100;
  background: var(--accent-deep-color);
  --text-color: white;
  color: var(--text-color);

  .navigation {
    display: flex;
    align-items: baseline;
    font-size: 0.8em;
    font-weight: bold;
    font-family: sans-serif;
  }

  a {
    color: var(--text-color);
    padding: 0.5em 0.7em;
    display: inline-block;
    text-decoration: none;

    &:hover {
      background: var(--accent-color);
      color: white;
    }
  }

  .spacer {
    flex-grow: 1;
  }
}
</style>
