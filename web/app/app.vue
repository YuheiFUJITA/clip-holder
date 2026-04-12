<script setup lang="ts">
useSchemaOrg([
  defineWebSite({
    name: 'ClipHolder',
  }),
  defineWebPage(),
])
</script>

<template>
  <div>
    <NuxtRouteAnnouncer />
    <NuxtPage />
  </div>
</template>
