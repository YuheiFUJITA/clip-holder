<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <UPageSection
    :headline="t('support.label')"
    :title="t('support.title')"
    :description="t('support.description')"
    orientation="vertical"
  >
    <template #links>
      <UButton
        :label="t('support.githubSponsors')"
        icon="i-lucide-heart"
        color="error"
        variant="soft"
        size="lg"
        to="https://github.com/sponsors/YuheiFUJITA"
        target="_blank"
      />
      <UButton
        :label="t('support.buyMeACoffee')"
        icon="i-simple-icons-buymeacoffee"
        color="warning"
        variant="soft"
        size="lg"
        to="https://buymeacoffee.com/yuhei_fujita"
        target="_blank"
      />
    </template>

    <p class="text-muted text-sm text-center">
      {{ t('support.note') }}
    </p>
  </UPageSection>
</template>
