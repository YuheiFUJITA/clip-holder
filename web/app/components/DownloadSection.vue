<script setup lang="ts">
const { t } = useI18n()
const { version, dmgUrl } = useLatestRelease()
</script>

<template>
  <section id="download" class="py-16 sm:py-24 lg:py-32">
    <UContainer>
      <div class="rounded-2xl bg-elevated p-12 sm:p-16 text-center">
        <h2 class="text-3xl sm:text-4xl font-bold text-highlighted mb-4">
          {{ t('download.title') }}
        </h2>
        <p class="text-muted text-base sm:text-lg mb-8 whitespace-pre-line">
          {{ t('download.description') }}
        </p>
        <div class="flex flex-col items-center gap-4">
          <UButton
            :label="t('download.cta')"
            icon="i-lucide-download"
            size="xl"
            :to="dmgUrl"
            download
          />
          <p v-if="version" class="text-dimmed text-sm">
            {{ version }}
          </p>
        </div>
      </div>
    </UContainer>
  </section>
</template>
