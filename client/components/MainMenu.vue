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
  --text-color: #111;
  --text-color-inverted: #fff;
  color: var(--text-color);
  background: rgba(255, 255, 255, 0.4);
  backdrop-filter: saturate(3) blur(1.5em) brightness(0.9);
  border-bottom: 1px solid #7773;

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
