<script setup lang="ts">
import type { FooterColumn } from '@nuxt/ui'

const { t } = useI18n()

const columns = computed<FooterColumn[]>(() => [
  {
    label: t('footer.project'),
    children: [
      {
        label: t('footer.sourceCode'),
        to: 'https://github.com/YuheiFUJITA/clip-holder',
        target: '_blank',
      },
      {
        label: t('footer.pastVersions'),
        to: 'https://github.com/YuheiFUJITA/clip-holder/releases',
        target: '_blank',
      },
      {
        label: t('footer.feedback'),
        to: 'https://github.com/YuheiFUJITA/clip-holder/issues',
        target: '_blank',
      },
    ],
  },
  {
    label: t('footer.support'),
    children: [
      {
        label: t('sponsor.githubSponsors'),
        to: 'https://github.com/sponsors/YuheiFUJITA',
        target: '_blank',
      },
      {
        label: t('sponsor.buyMeACoffee'),
        to: 'https://buymeacoffee.com/yuhei_fujita',
        target: '_blank',
      },
    ],
  },
])
</script>

<template>
  <footer class="border-t border-border">
    <UContainer>
      <div class="grid grid-cols-2 sm:grid-cols-3 gap-8 py-12">
        <div v-for="column in columns" :key="column.label">
          <h4 class="text-highlighted font-semibold text-sm mb-4">
            {{ column.label }}
          </h4>
          <ul class="space-y-2">
            <li v-for="child in column.children" :key="child.label">
              <ULink
                :to="child.to"
                :target="child.target"
                class="text-muted text-sm hover:text-highlighted transition-colors"
              >
                {{ child.label }}
              </ULink>
            </li>
          </ul>
        </div>

        <div>
          <h4 class="text-highlighted font-semibold text-sm mb-4">
            ClipHolder
          </h4>
          <p class="text-muted text-sm whitespace-pre-line">
            {{ t('footer.appDescription') }}
          </p>
        </div>
      </div>
    </UContainer>

    <UContainer>
      <div class="flex items-center justify-between py-6 border-t border-border">
        <p class="text-dimmed text-xs">
          {{ t('footer.copyright') }}
        </p>
        <UButton
          icon="i-simple-icons-github"
          color="neutral"
          variant="ghost"
          to="https://github.com/YuheiFUJITA/clip-holder"
          target="_blank"
          aria-label="GitHub"
        />
      </div>
    </UContainer>
  </footer>
</template>
