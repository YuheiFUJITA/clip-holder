<script setup lang="ts">
import type { NavigationMenuItem, DropdownMenuItem } from '@nuxt/ui'

const { t, locale, locales } = useI18n()
const switchLocalePath = useSwitchLocalePath()
const localePath = useLocalePath()

const navItems = computed<NavigationMenuItem[]>(() => [
  {
    label: t('nav.features'),
    to: localePath({ hash: '#features' }),
  },
  {
    label: t('nav.download'),
    to: localePath({ hash: '#download' }),
  },
  {
    label: t('nav.github'),
    icon: 'i-simple-icons-github',
    to: 'https://github.com/YuheiFUJITA/clip-holder',
    target: '_blank',
  },
])

const sponsorItems = computed<DropdownMenuItem[][]>(() => [[
  {
    label: t('sponsor.githubSponsors'),
    icon: 'i-simple-icons-githubsponsors',
    to: 'https://github.com/sponsors/YuheiFUJITA',
    target: '_blank',
  },
  {
    label: t('sponsor.buyMeACoffee'),
    icon: 'i-simple-icons-buymeacoffee',
    to: 'https://buymeacoffee.com/yuhei_fujita',
    target: '_blank',
  },
]])

const availableLocales = computed(() =>
  (locales.value as Array<{ code: string; name: string }>).map(l => ({
    label: l.name,
    value: l.code,
  }))
)

function onLocaleChange(code: string) {
  navigateTo(switchLocalePath(code))
}
</script>

<template>
  <UHeader :ui="{ root: 'sticky top-0 z-50 backdrop-blur-md bg-background/80' }">
    <template #title>
      <NuxtLink :to="localePath('/')" class="text-lg font-bold text-highlighted hover:text-highlighted">
        ClipHolder
      </NuxtLink>
    </template>

    <UNavigationMenu :items="navItems" variant="link" />

    <template #right>
      <UDropdownMenu :items="sponsorItems">
        <UButton
          color="error"
          variant="soft"
          icon="i-lucide-heart"
          :label="t('nav.sponsor')"
          trailing-icon="i-lucide-chevron-down"
          size="sm"
        />
      </UDropdownMenu>

      <USelectMenu
        :model-value="locale"
        :items="availableLocales"
        value-key="value"
        size="sm"
        variant="ghost"
        color="neutral"
        class="w-40"
        @update:model-value="onLocaleChange"
      />
    </template>

    <template #body>
      <UNavigationMenu :items="navItems" orientation="vertical" class="-mx-2.5" />

      <UDropdownMenu :items="sponsorItems">
        <UButton
          color="error"
          variant="soft"
          icon="i-lucide-heart"
          :label="t('nav.sponsor')"
          trailing-icon="i-lucide-chevron-down"
          size="sm"
          class="mt-4"
        />
      </UDropdownMenu>
    </template>
  </UHeader>
</template>
