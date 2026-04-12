<script setup lang="ts">
const { t } = useI18n()

const features = computed(() => [
  {
    icon: 'i-lucide-clipboard-list',
    title: t('features.items.history.title'),
    description: t('features.items.history.description'),
  },
  {
    icon: 'i-lucide-keyboard',
    title: t('features.items.keyboard.title'),
    description: t('features.items.keyboard.description'),
  },
  {
    icon: 'i-lucide-file-image',
    title: t('features.items.multiContent.title'),
    description: t('features.items.multiContent.description'),
  },
  {
    icon: 'i-lucide-languages',
    title: t('features.items.multilingual.title'),
    description: t('features.items.multilingual.description'),
  },
])
</script>

<template>
  <UPageSection
    id="features"
    :headline="t('features.label')"
    :title="t('features.title')"
    :description="t('features.description')"
    orientation="vertical"
    :ui="{
      features: 'sm:grid-cols-2 lg:grid-cols-4 gap-6',
    }"
  >
    <template #features>
      <div
        v-for="(feature, index) in features"
        :key="index"
        class="rounded-2xl bg-elevated p-6"
      >
        <div class="size-12 rounded-xl border border-primary bg-accented flex items-center justify-center mb-4">
          <UIcon :name="feature.icon" class="size-5 text-primary" />
        </div>
        <h3 class="text-highlighted font-semibold text-lg mb-2">
          {{ feature.title }}
        </h3>
        <p class="text-muted text-sm leading-relaxed">
          {{ feature.description }}
        </p>
      </div>
    </template>
  </UPageSection>
</template>
