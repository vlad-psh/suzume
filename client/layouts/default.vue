<template>
  <div id="__layout_inner">
    <MainMenu />
    <Nuxt />
  </div>
</template>

<script>
export default {}
</script>

<style lang="scss">
body {
  margin: 0;
  padding-top: 7em;
  padding-bottom: 4em;
  font-family: Segoe UI, Helvetica Neue, sans-serif;

  --accent-pale-color: #ea734e;
  --accent-color: #c53342;
  --accent-deep-color: #b8002b;

  a {
    color: #008ace;
    cursor: pointer;
    &:hover {
      color: #c00;
    }
  }
}
</style>
