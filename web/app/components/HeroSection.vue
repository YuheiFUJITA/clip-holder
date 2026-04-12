<script setup lang="ts">
const { t } = useI18n()
const { version, dmgUrl } = useLatestRelease()
</script>

<template>
  <UPageHero
    orientation="horizontal"
    :headline="t('hero.headline')"
    :title="t('hero.title')"
    :description="t('hero.description')"
    :ui="{
      root: 'bg-gradient-to-b from-violet-950/60 to-transparent',
      title: 'text-5xl sm:text-7xl',
    }"
  >
    <template #links>
      <UButton
        :label="t('hero.cta')"
        icon="i-lucide-download"
        size="xl"
        :to="dmgUrl"
        download
      />
      <p v-if="version" class="text-muted text-sm self-center">
        {{ version }}
      </p>
    </template>

    <div class="relative flex items-center justify-center">
      <div class="absolute w-[120%] h-[120%] bg-gradient-to-br from-violet-500/15 to-indigo-500/10 rounded-full blur-2xl" />
      <img
        src="/icon.png"
        alt="ClipHolder"
        class="relative w-64 h-64 sm:w-80 sm:h-80 lg:w-96 lg:h-96 rounded-3xl"
      >
    </div>
  </UPageHero>
</template>
