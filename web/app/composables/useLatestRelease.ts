interface ReleaseAsset {
  name: string
  browser_download_url: string
}

interface ReleaseResponse {
  tag_name: string
  assets: ReleaseAsset[]
}

const FALLBACK_URL = 'https://github.com/YuheiFUJITA/clip-holder/releases'

export function useLatestRelease() {
  const { data } = useAsyncData('latest-release', () =>
    $fetch<ReleaseResponse>(
      'https://api.github.com/repos/YuheiFUJITA/clip-holder/releases/latest',
    ).then((release) => {
      const dmg = release.assets.find(a => a.name.endsWith('.dmg'))
      return {
        tag_name: release.tag_name,
        dmgUrl: dmg?.browser_download_url || FALLBACK_URL,
      }
    }).catch(() => ({
      tag_name: '',
      dmgUrl: FALLBACK_URL,
    })),
  )

  const version = computed(() => data.value?.tag_name ?? '')
  const dmgUrl = computed(() => data.value?.dmgUrl ?? FALLBACK_URL)

  return { version, dmgUrl }
}
