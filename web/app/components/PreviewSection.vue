<template>
  <section class="py-16 sm:py-24 lg:py-32 relative overflow-hidden">
    <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
      <div class="w-[1000px] h-[500px] bg-primary/8 rounded-full blur-[100px]" />
    </div>

    <UContainer class="relative">
      <div class="rounded-xl border border-[var(--ui-border)] overflow-hidden shadow-2xl shadow-black/50 max-w-4xl mx-auto">
        <div class="h-8 bg-[var(--ui-bg-elevated)] flex items-center gap-2 px-3">
          <span class="size-3 rounded-full bg-[#FF5F57]" />
          <span class="size-3 rounded-full bg-[#FEBD2E]" />
          <span class="size-3 rounded-full bg-[#28C940]" />
        </div>
        <img
          src="/screenshot.webp"
          alt="ClipHolder"
          class="w-full block"
        >
      </div>
    </UContainer>
  </section>
</template>
