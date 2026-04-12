interface ReleaseAsset {
  name: string
  browser_download_url: string
}

interface ReleaseResponse {
  tag_name: string
  assets: ReleaseAsset[]
}

export function useLatestRelease() {
  const { data } = useFetch<ReleaseResponse>(
    'https://api.github.com/repos/YuheiFUJITA/clip-holder/releases/latest',
    {
      key: 'latest-release',
      transform: (release) => {
        const dmg = release.assets.find(a => a.name.endsWith('.dmg'))
        return {
          tag_name: release.tag_name,
          dmgUrl: dmg?.browser_download_url || 'https://github.com/YuheiFUJITA/clip-holder/releases',
        }
      },
    },
  )

  const version = computed(() => data.value?.tag_name ?? '')
  const dmgUrl = computed(() => data.value?.dmgUrl ?? 'https://github.com/YuheiFUJITA/clip-holder/releases')

  return { version, dmgUrl }
}
