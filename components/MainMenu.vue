<template>
  <div>
    <template v-if="$store.state.env.user">
      <NuxtLink to="/">Index</NuxtLink>
      <NuxtLink to="/abyss">Abyss</NuxtLink>
      {{ $store.state.env.user.username }}
      <a @click="$auth.logout">logout</a>
    </template>
    <template v-else>
      <NuxtLink to="/login">login</NuxtLink>
    </template>
  </div>
</template>
