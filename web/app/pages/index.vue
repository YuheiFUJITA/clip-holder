<script setup lang="ts">
const { t } = useI18n()

useSeoMeta({
  title: () => t('meta.title'),
  description: () => t('meta.description'),
  ogImage: '/og-image.png',
  ogType: 'website',
})
</script>

<template>
  <UApp>
    <AppHeader />

    <UMain>
      <HeroSection />
      <PreviewSection />
      <FeaturesSection />
      <SupportSection />
      <DownloadSection />
    </UMain>

    <AppFooter />
  </UApp>
</template>

<style>
html {
  scroll-behavior: smooth;
}
</style>
