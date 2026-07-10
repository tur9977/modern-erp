<template>
  <div class="placeholder-container animate-fade-in">
    <div class="glass-card text-center">
      <h1 class="page-title">{{ moduleName }}</h1>
      <p class="subtitle">此模組正在由 Antigravity 努力建置中 🚀</p>
      
      <div class="illustration">
        <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="var(--primary-color)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
          <line x1="3" y1="9" x2="21" y2="9"/>
          <line x1="9" y1="21" x2="9" y2="9"/>
        </svg>
      </div>

      <div class="message">
        <p>目前架構地基（PostgreSQL 資料表）已全部上線！</p>
        <p>我們將會在後續的階段，一步步為這裡加上專屬的業務邏輯與精美介面。</p>
      </div>

      <router-link to="/" class="btn btn-primary mt-4">回控制面板</router-link>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

export default {
  name: 'Placeholder',
  setup() {
    const route = useRoute()
    
    // 從路由 meta 中獲取模組名稱，如果沒有則顯示路由路徑
    const moduleName = computed(() => route.meta.title || route.path)

    return {
      moduleName
    }
  }
}
</script>

<style scoped>
.placeholder-container {
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - var(--toolbar-height) - 4rem);
}

.text-center {
  text-align: center;
}

.illustration {
  margin: 2rem 0;
  opacity: 0.8;
}

.message {
  color: var(--text-secondary);
  line-height: 1.8;
  margin-bottom: 2rem;
}

.mt-4 {
  margin-top: 1.5rem;
}
</style>
