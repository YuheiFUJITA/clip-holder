<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <UAlert
    color="warning"
    variant="subtle"
    icon="i-lucide-triangle-alert"
    :title="t('notice.title')"
    :description="t('notice.description')"
    :actions="[
      {
        label: t('notice.cta'),
        to: 'https://github.com/YuheiFUJITA/clip-holder/releases/tag/v0.2.1',
        target: '_blank',
        color: 'warning',
        variant: 'solid',
        icon: 'i-lucide-download',
      },
    ]"
    class="rounded-none border-x-0 border-t-0"
  />
</template>
