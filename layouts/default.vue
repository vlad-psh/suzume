<template>
  <div id="__layout_inner">
    <MainMenu />
    <Nuxt keep-alive />
  </div>
</template>

<script>
export default {}
</script>

<style lang="scss">
body {
  margin: 0;
  padding-top: 6.5em;

  a {
    color: #008ace;
    cursor: pointer;
    &:hover {
      color: #c00;
    }
  }
}
</style>
