import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
import './style.css'

const app = createApp(App)

// Global dummy apiClient to prevent crashes in unmigrated modules
window.apiClient = {
  get: async () => ({ data: [] }),
  post: async () => ({ data: [] }),
  put: async () => ({ data: [] }),
  delete: async () => ({ data: [] })
}

app.use(createPinia())
app.use(router)

app.mount('#app')
/* cache bust Sat Jul 11 00:11:30 CST 2026 */
