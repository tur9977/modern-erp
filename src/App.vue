<template>
  <div class="app-container" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    <!-- Left Sidebar - 10 System Navigation -->
    <aside class="sidebar">
      <div class="brand">
        <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#D4A84B" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></svg>
        <span class="brand-text">DOUBLE ERP</span>
      </div>

      <nav class="system-nav">
        <!-- 首頁 -->
        <div class="system-group">
          <router-link to="/" class="system-header" active-class="active">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>
            <span>首頁</span>
          </router-link>
        </div>

        <!-- CRM 客戶中心 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('crm')" :class="{ expanded: expandedGroups.crm }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            <span>CRM</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.crm">
            <router-link to="/crm" class="system-item" active-class="active">📊 CRM 儀表板</router-link>
            <router-link to="/customers" class="system-item" active-class="active">客戶總覽</router-link>
            <router-link to="/member-tiers" class="system-item" active-class="active">⭐ 會員等級</router-link>
            <router-link to="/crm/channels" class="system-item" active-class="active">通路主檔</router-link>
            <router-link to="/crm/collection-targets" class="system-item" active-class="active">請款對象</router-link>
            <router-link to="/crm/payment-methods" class="system-item" active-class="active">收款方式</router-link>
          </div>
        </div>

        <!-- 託售系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('consignment')" :class="{ expanded: expandedGroups.consignment }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>
            <span>託售</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.consignment">
            <router-link to="/consignments" class="system-item" active-class="active">託售出貨單</router-link>
            <router-link to="/consignment/returns" class="system-item" active-class="active">託售退貨</router-link>
            <router-link to="/settlements" class="system-item" active-class="active">月底結帳</router-link>
          </div>
        </div>

        <!-- 銷售系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('sales')" :class="{ expanded: expandedGroups.sales }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
            <span>銷售</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.sales">
            <router-link to="/orders" class="system-item" active-class="active">直銷銷貨單</router-link>
            <router-link to="/sales/returns" class="system-item" active-class="active">銷售退貨</router-link>
            <router-link to="/sales/quotes" class="system-item" active-class="active">報價單</router-link>
          </div>
        </div>

        <!-- 庫存系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('inventory')" :class="{ expanded: expandedGroups.inventory }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><path d="M3.27 6.96 12 12l8.73-5.04M12 22V12"/></svg>
            <span>採購與庫存</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.inventory">
            <router-link to="/inventory" class="system-item" active-class="active">📦 庫存儀表板</router-link>
            <router-link to="/inventory/lots" class="system-item" active-class="active">FIFO 批次</router-link>
            <router-link to="/inventory/transactions" class="system-item" active-class="active">異動履歷</router-link>
            <router-link to="/inventory/items" class="system-item" active-class="active">商品主檔</router-link>
          </div>
        </div>

        <!-- 採購系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('procurement')" :class="{ expanded: expandedGroups.procurement }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18M16 10a4 4 0 0 1-8 0"/></svg>
            <span>採購</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.procurement">
            <router-link to="/procurement/vendors" class="system-item" active-class="active">廠商主檔</router-link>
            <router-link to="/procurement/orders" class="system-item" active-class="active">採購單</router-link>
            <router-link to="/procurement/receipts" class="system-item" active-class="active">進貨驗收</router-link>
          </div>
        </div>

        <!-- 生產系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('production')" :class="{ expanded: expandedGroups.production }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 20a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8l-7 5V8l-7 5V4a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z"/></svg>
            <span>生產</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.production">
            <router-link to="/production/boms" class="system-item" active-class="active">BOM 主檔</router-link>
            <router-link to="/production/work-orders" class="system-item" active-class="active">工單管理</router-link>
            <router-link to="/production/schedule" class="system-item" active-class="active">生產排程</router-link>
          </div>
        </div>

        <!-- POS 系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('pos')" :class="{ expanded: expandedGroups.pos }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M12 8v8M8 12h8"/></svg>
            <span>POS</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.pos">
            <router-link to="/pos/checkout" class="system-item" active-class="active">收銀台</router-link>
            <router-link to="/pos/transactions" class="system-item" active-class="active">交易記錄</router-link>
            <router-link to="/pos/shifts" class="system-item" active-class="active">班別交接</router-link>
          </div>
        </div>

        <!-- 會計系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('accounting')" :class="{ expanded: expandedGroups.accounting }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
            <span>會計</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.accounting">
            <router-link to="/accounting/gl" class="system-item" active-class="active">總帳分錄</router-link>
            <router-link to="/accounting/ar" class="system-item" active-class="active">應收帳款</router-link>
            <router-link to="/accounting/ap" class="system-item" active-class="active">應付帳款</router-link>
          </div>
        </div>

        <!-- 人事系統 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('hr')" :class="{ expanded: expandedGroups.hr }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" y1="8" x2="19" y2="14"/><line x1="22" y1="11" x2="16" y2="11"/></svg>
            <span>人事</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.hr">
            <router-link to="/hr/employees" class="system-item" active-class="active">員工主檔</router-link>
            <router-link to="/hr/departments" class="system-item" active-class="active">部門管理</router-link>
            <router-link to="/hr/attendance" class="system-item" active-class="active">出勤打卡</router-link>
          </div>
        </div>

        <!-- 系統管理 -->
        <div class="system-group">
          <button class="system-header" @click="toggleGroup('system')" :class="{ expanded: expandedGroups.system }">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
            <span>系統</span>
            <svg class="chevron" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
          </button>
          <div class="system-items" v-show="expandedGroups.system">
            <router-link to="/admin" class="system-item" active-class="active">數據管理</router-link>
            <router-link to="/research" class="system-item" active-class="active">資料庫研究</router-link>
            <router-link to="/system/roles" class="system-item" active-class="active">角色權限</router-link>
            <router-link to="/system/settings" class="system-item" active-class="active">系統設定</router-link>
          </div>
        </div>
      </nav>

      <!-- Sidebar Toggle -->
      <button class="sidebar-toggle" @click="toggleSidebar" :title="sidebarCollapsed ? '展開側邊欄' : '收合側邊欄'">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline :points="sidebarCollapsed ? '9 18 15 12 9 6' : '15 18 9 12 15 6'"/></svg>
      </button>
    </aside>

    <!-- Main Content Area -->
    <div class="main-wrapper">
      <!-- Top Global Toolbar -->
      <header class="top-toolbar">
        <div class="toolbar-left">
          <!-- Breadcrumb Navigation -->
          <nav class="breadcrumb" aria-label="breadcrumb">
            <router-link to="/" class="breadcrumb-item">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
              首頁
            </router-link>
            <template v-for="(crumb, index) in breadcrumbs" :key="index">
              <span class="breadcrumb-separator">/</span>
              <router-link v-if="crumb.path" :to="crumb.path" class="breadcrumb-item">{{ crumb.name }}</router-link>
              <span v-else class="breadcrumb-item current">{{ crumb.name }}</span>
            </template>
          </nav>
        </div>

        <div class="toolbar-right">
          <!-- Search Command -->
          <button class="toolbar-btn search-btn" @click="$emit('openSearch')" title="搜尋 (Cmd+K)">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            <span class="search-hint">Cmd+K</span>
          </button>

          <!-- Quick Create -->
          <button class="toolbar-btn" title="快速新增">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          </button>

          <!-- Favorites -->
          <button class="toolbar-btn" title="收藏">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          </button>

          <!-- Notifications -->
          <button class="toolbar-btn notification-btn" title="通知">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            <span class="notification-badge" v-if="notificationCount > 0">{{ notificationCount }}</span>
          </button>

          <!-- User Menu -->
          <div class="user-menu">
            <button class="user-btn" @click="toggleUserMenu">
              <div class="user-avatar">{{ userAvatar }}</div>
              <span class="user-name">{{ userName }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
            </button>
            <div class="user-dropdown" v-show="userMenuOpen">
              <router-link to="/profile" class="dropdown-item">個人資料</router-link>
              <router-link to="/settings" class="dropdown-item">設定</router-link>
              <hr class="dropdown-divider">
              <button class="dropdown-item" @click="logout">登出</button>
            </div>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="main-content">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>
    </div>
  </div>
</template>

<script>
import { computed, ref, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'

export default {
  name: 'App',
  setup() {
    const route = useRoute()
    const router = useRouter()

    // Sidebar state
    const sidebarCollapsed = ref(false)
    const expandedGroups = reactive({
      crm: false,
      consignment: false,
      sales: false,
      inventory: false,
      procurement: false,
      production: false,
      pos: false,
      accounting: false,
      hr: false,
      system: false
    })

    // User menu
    const userMenuOpen = ref(false)
    const notificationCount = ref(0)

    // User info from localStorage
    const currentUser = ref(null)
    try {
      const stored = localStorage.getItem('user')
      if (stored) {
        currentUser.value = JSON.parse(stored)
      }
    } catch (e) {
      console.error(e)
    }

    const userName = computed(() => {
      if (currentUser.value && currentUser.value.name) return currentUser.value.name
      if (currentUser.value && currentUser.value.username) return currentUser.value.username
      if (currentUser.value && currentUser.value.code) return currentUser.value.code
      return 'Neal'
    })
    
    const userAvatar = computed(() => {
      const name = userName.value
      return name ? name.charAt(0).toUpperCase() : 'N'
    })

    // Toggle functions
    const toggleGroup = (group) => {
      expandedGroups[group] = !expandedGroups[group]
    }

    const toggleSidebar = () => {
      sidebarCollapsed.value = !sidebarCollapsed.value
    }

    const toggleUserMenu = () => {
      userMenuOpen.value = !userMenuOpen.value
    }

    const logout = () => {
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      localStorage.removeItem('user')
      userMenuOpen.value = false
      router.push('/login')
    }

    // Compute breadcrumbs based on current route
    const breadcrumbs = computed(() => {
      const path = route.path
      const crumbs = []

      // Map routes to breadcrumb structure
      if (path.startsWith('/customers') || path.startsWith('/crm/')) {
        crumbs.push({ name: 'CRM', path: '/customers' })
        if (path.includes('/channels')) crumbs.push({ name: '通路主檔' })
        else if (path.includes('/collection-targets')) crumbs.push({ name: '請款對象' })
        else if (path.includes('/payment-methods')) crumbs.push({ name: '收款方式' })
        else crumbs.push({ name: '客戶總覽' })
      }
      else if (path.startsWith('/consignments') || path.startsWith('/consignment/') || path === '/settlements') {
        crumbs.push({ name: '託售', path: '/consignments' })
        if (path.includes('/returns')) crumbs.push({ name: '託售退貨' })
        else if (path === '/settlements') crumbs.push({ name: '月底結帳' })
        else crumbs.push({ name: '託售出貨單' })
      }
      else if (path.startsWith('/orders') || path.startsWith('/sales/')) {
        crumbs.push({ name: '銷售', path: '/orders' })
        if (path.includes('/returns')) crumbs.push({ name: '銷售退貨' })
        else if (path.includes('/quotes')) crumbs.push({ name: '報價單' })
        else crumbs.push({ name: '直銷銷貨單' })
      }
      else if (path.startsWith('/inventory/')) {
        crumbs.push({ name: '庫存', path: '/inventory/stock' })
        if (path.includes('/lots')) crumbs.push({ name: 'FIFO 批次' })
        else if (path.includes('/transactions')) crumbs.push({ name: '異動履歷' })
        else if (path.includes('/items')) crumbs.push({ name: '商品主檔' })
        else crumbs.push({ name: '庫存查詢' })
      }
      else if (path.startsWith('/procurement/')) {
        crumbs.push({ name: '採購', path: '/procurement/vendors' })
        if (path.includes('/orders')) crumbs.push({ name: '採購單' })
        else if (path.includes('/receipts')) crumbs.push({ name: '進貨驗收' })
        else crumbs.push({ name: '廠商主檔' })
      }
      else if (path.startsWith('/production/')) {
        crumbs.push({ name: '生產', path: '/production/boms' })
        if (path.includes('/work-orders')) crumbs.push({ name: '工單管理' })
        else if (path.includes('/schedule')) crumbs.push({ name: '生產排程' })
        else crumbs.push({ name: 'BOM 主檔' })
      }
      else if (path.startsWith('/pos/')) {
        crumbs.push({ name: 'POS', path: '/pos/checkout' })
        if (path.includes('/transactions')) crumbs.push({ name: '交易記錄' })
        else if (path.includes('/shifts')) crumbs.push({ name: '班別交接' })
        else crumbs.push({ name: '收銀台' })
      }
      else if (path.startsWith('/accounting/')) {
        crumbs.push({ name: '會計', path: '/accounting/gl' })
        if (path.includes('/ar')) crumbs.push({ name: '應收帳款' })
        else if (path.includes('/ap')) crumbs.push({ name: '應付帳款' })
        else crumbs.push({ name: '總帳分錄' })
      }
      else if (path.startsWith('/hr/')) {
        crumbs.push({ name: '人事', path: '/hr/employees' })
        if (path.includes('/departments')) crumbs.push({ name: '部門管理' })
        else if (path.includes('/attendance')) crumbs.push({ name: '出勤打卡' })
        else crumbs.push({ name: '員工主檔' })
      }
      else if (path.startsWith('/admin') || path.startsWith('/research') || path.startsWith('/system/')) {
        crumbs.push({ name: '系統', path: '/admin' })
        if (path.startsWith('/research')) crumbs.push({ name: '資料庫研究' })
        else if (path.includes('/roles')) crumbs.push({ name: '角色權限' })
        else if (path.includes('/settings')) crumbs.push({ name: '系統設定' })
        else crumbs.push({ name: '數據管理' })
      }
      else if (path === '/') {
        crumbs.push({ name: '控制面板' })
      }

      return crumbs
    })

    return {
      sidebarCollapsed,
      expandedGroups,
      userMenuOpen,
      notificationCount,
      toggleGroup,
      toggleSidebar,
      toggleUserMenu,
      logout,
      breadcrumbs
    }
  }
}
</script>

<style>
/* ============================================================================
   DOUBLE ERP - 優雅米色設計系統 (Linear/Notion 風格)
   ============================================================================ */

:root {
  /* 側邊欄 */
  --sidebar-width: 240px;
  --sidebar-collapsed-width: 60px;
  --toolbar-height: 52px;

  /* 優雅米色配色 */
  --primary-color: #8B6914;
  --primary-hover: #6B5210;
  --primary-light: #F5EBD8;

  /* 背景層次 */
  --bg-sidebar: #2C2824;
  --bg-sidebar-hover: #3A352F;
  --bg-toolbar: #FDFBF7;
  --bg-main: #F5F1EA;
  --bg-card: #FFFFFF;
  --bg-hover: rgba(139, 105, 20, 0.04);

  /* 字體層次 */
  --text-primary: #1A1814;
  --text-secondary: #6B635B;
  --text-muted: #9A9189;
  --text-sidebar: #E8E2D9;
  --text-sidebar-muted: #A8A095;

  /* 邊框 */
  --border-color: #E8E0D5;
  --border-light: #F0EBE3;

  /* 陰影 */
  --shadow-xs: 0 1px 2px rgba(45, 41, 38, 0.04);
  --shadow-sm: 0 1px 3px rgba(45, 41, 38, 0.06);
  --shadow-md: 0 4px 12px rgba(45, 41, 38, 0.08);
  --shadow-lg: 0 8px 24px rgba(45, 41, 38, 0.12);

  /* 狀態 */
  --success: #4A7C59;
  --warning: #B8860B;
  --danger: #A63D40;
  --info: #5B7B8A;

  /* 圓角 */
  --radius-xs: 4px;
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
}

/* ============================================================================
   App Layout
   ============================================================================ */

.app-container {
  display: flex;
  min-height: 100vh;
  background: var(--bg-main);
}

/* ============================================================================
   Sidebar
   ============================================================================ */

.sidebar {
  width: var(--sidebar-width);
  background: var(--bg-sidebar);
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  z-index: 100;
  transition: width 0.2s ease;
  overflow: hidden;
}

.app-container.sidebar-collapsed .sidebar {
  width: var(--sidebar-collapsed-width);
}

/* Brand / Logo */
.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 16px;
  border-bottom: 1px solid rgba(255,255,255,0.06);
  color: #F5F0E8;
  overflow: hidden;
  white-space: nowrap;
}

.brand svg {
  width: 22px;
  height: 22px;
  color: #D4A84B;
  flex-shrink: 0;
}

.brand-text {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.3px;
  color: #E8E2D9;
}

.sidebar-collapsed .brand-text,
.sidebar-collapsed .chevron {
  opacity: 0;
}

/* ============================================================================
   Navigation
   ============================================================================ */

.system-nav {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 8px 0;
}

.system-nav::-webkit-scrollbar {
  width: 3px;
}

.system-nav::-webkit-scrollbar-thumb {
  background: rgba(255,255,255,0.1);
  border-radius: 2px;
}

/* System Group */
.system-group {
  margin: 2px 0;
}

.system-header {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 8px 12px;
  color: var(--text-sidebar-muted);
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  background: transparent;
  border: none;
  text-align: left;
  overflow: hidden;
  white-space: nowrap;
  border-radius: var(--radius-sm);
  margin: 0 6px;
}

.system-header:hover {
  background: var(--bg-sidebar-hover);
  color: var(--text-sidebar);
}

.system-header.active,
.system-header.router-link-active {
  background: rgba(139, 105, 20, 0.2);
  color: #D4A84B;
}

.system-header svg {
  width: 16px;
  height: 16px;
  flex-shrink: 0;
  opacity: 0.7;
}

.system-header:hover svg,
.system-header.active svg {
  opacity: 1;
}

.system-header span {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chevron {
  width: 14px;
  height: 14px;
  opacity: 0.5;
  transition: transform 0.2s ease;
}

.system-header.expanded .chevron {
  transform: rotate(180deg);
}

/* Sub Items */
.system-items {
  padding: 2px 0 4px 0;
}

.system-item {
  display: block;
  padding: 6px 12px 6px 38px;
  color: var(--text-sidebar-muted);
  text-decoration: none;
  font-size: 12.5px;
  transition: all 0.15s ease;
  border-radius: var(--radius-sm);
  margin: 1px 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.system-item:hover {
  background: var(--bg-sidebar-hover);
  color: var(--text-sidebar);
}

.system-item.active,
.system-item.router-link-active {
  background: rgba(139, 105, 20, 0.15);
  color: #D4A84B;
}

/* Sidebar Toggle */
.sidebar-toggle {
  position: absolute;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255,255,255,0.06);
  border: none;
  padding: 6px;
  border-radius: var(--radius-sm);
  color: var(--text-sidebar-muted);
  cursor: pointer;
  transition: all 0.15s ease;
}

.sidebar-toggle:hover {
  background: rgba(255,255,255,0.1);
  color: var(--text-sidebar);
}

/* ============================================================================
   Main Wrapper
   ============================================================================ */

.main-wrapper {
  flex: 1;
  margin-left: var(--sidebar-width);
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  transition: margin-left 0.2s ease;
}

.app-container.sidebar-collapsed .main-wrapper {
  margin-left: var(--sidebar-collapsed-width);
}

/* ============================================================================
   Top Toolbar
   ============================================================================ */

.top-toolbar {
  height: var(--toolbar-height);
  background: var(--bg-toolbar);
  border-bottom: 1px solid var(--border-light);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  position: sticky;
  top: 0;
  z-index: 50;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Breadcrumb */
.breadcrumb {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

.breadcrumb-item {
  display: flex;
  align-items: center;
  gap: 4px;
  color: var(--text-muted);
  text-decoration: none;
  transition: color 0.15s;
}

.breadcrumb-item:hover {
  color: var(--primary-color);
}

.breadcrumb-item.current {
  color: var(--text-primary);
  font-weight: 500;
}

.breadcrumb-item svg {
  width: 12px;
  height: 12px;
}

.breadcrumb-separator {
  color: var(--border-color);
  font-size: 11px;
}

/* Toolbar Buttons */
.toolbar-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 6px 10px;
  background: transparent;
  border: none;
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.15s;
  font-size: 12px;
}

.toolbar-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.toolbar-btn svg {
  width: 16px;
  height: 16px;
}

.search-btn {
  background: var(--bg-main);
  padding: 6px 12px;
  border: 1px solid var(--border-color);
}

.search-hint {
  font-size: 11px;
  color: var(--text-muted);
  background: var(--bg-card);
  padding: 2px 5px;
  border-radius: 3px;
  border: 1px solid var(--border-light);
}

/* Notification Badge */
.notification-btn {
  position: relative;
}

.notification-badge {
  position: absolute;
  top: 2px;
  right: 2px;
  background: var(--danger);
  color: #fff;
  font-size: 9px;
  padding: 1px 4px;
  border-radius: 10px;
  min-width: 14px;
  text-align: center;
  font-weight: 600;
}

/* User Menu */
.user-menu {
  position: relative;
}

.user-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 8px 4px 4px;
  background: transparent;
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.15s;
}

.user-btn:hover {
  background: var(--bg-main);
  border-color: var(--primary-light);
}

.user-avatar {
  width: 24px;
  height: 24px;
  background: var(--primary-color);
  color: #fff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
}

.user-name {
  font-size: 12.5px;
  color: var(--text-primary);
}

.user-btn svg {
  width: 12px;
  height: 12px;
  color: var(--text-muted);
}

.user-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 6px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  min-width: 150px;
  overflow: hidden;
  z-index: 100;
}

.dropdown-item {
  display: block;
  width: 100%;
  padding: 8px 14px;
  color: var(--text-primary);
  text-decoration: none;
  font-size: 13px;
  text-align: left;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}

.dropdown-item:hover {
  background: var(--bg-main);
}

.dropdown-divider {
  margin: 4px 0;
  border: none;
  border-top: 1px solid var(--border-light);
}

/* ============================================================================
   Main Content
   ============================================================================ */

.main-content {
  flex: 1;
  padding: 24px 28px;
}

/* Page transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(4px);
}

/* ============================================================================
   Responsive
   ============================================================================ */

@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
  }

  .app-container.sidebar-collapsed .sidebar {
    transform: translateX(0);
  }

  .main-wrapper {
    margin-left: 0 !important;
  }

  .search-hint {
    display: none;
  }
}
</style>