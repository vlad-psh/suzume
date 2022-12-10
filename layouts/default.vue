<template>
  <div id="__layout_inner">
    <MainMenu />
    <Nuxt keep-alive />
    <MediaPlayer v-if="$store.state.env.user" />
  </div>
</template>

<script>
export default {}
</script>

<style lang="scss">
body {
  margin: 0;
  padding-top: 2.5em;
  padding-bottom: 4em;
  font-family: Segoe UI, Helvetica Neue, sans-serif;

  a {
    color: #008ace;
    cursor: pointer;
    &:hover {
      color: #c00;
    }
  }
}
</style>
