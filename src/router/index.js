import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'
import Orders from '../views/Orders.vue'
import Customers from '../views/Customers.vue'
import InventoryItems from '../views/InventoryItems.vue'
import Placeholder from '../views/Placeholder.vue'

// 新匯入的 20 個 Vue 模組
import CrmDashboard from '../views/CrmDashboard.vue'
import MemberTiers from '../views/MemberTiers.vue'
import Consignments from '../views/Consignments.vue'
import Settlements from '../views/Settlements.vue'
import InventoryDashboard from '../views/InventoryDashboard.vue'
import InventoryLots from '../views/InventoryLots.vue'
import PurchaseOrders from '../views/PurchaseOrders.vue'
import WorkOrders from '../views/WorkOrders.vue'
import POSCheckout from '../views/POSCheckout.vue'
import POSTransactions from '../views/POSTransactions.vue'
import HRAttendance from '../views/HRAttendance.vue'
import HRLeave from '../views/HRLeave.vue'
import DataAdmin from '../views/DataAdmin.vue'
import DatabaseResearch from '../views/DatabaseResearch.vue'
import RoleManagement from '../views/RoleManagement.vue'
import Profile from '../views/Profile.vue'
import Login from '../views/Login.vue'
import Quotes from '../views/Quotes.vue'
import Returns from '../views/Returns.vue'
import AccountingPeriods from '../views/AccountingPeriods.vue'

// Define the routes corresponding to all modules in App.vue
const routes = [
  { path: '/', name: 'Dashboard', component: Dashboard, meta: { title: '控制面板' } },
  { path: '/login', name: 'Login', component: Login, meta: { title: '登入' } },
  { path: '/profile', name: 'Profile', component: Profile, meta: { title: '個人資料' } },
  
  // CRM
  { path: '/crm', name: 'CRM_Dashboard', component: CrmDashboard, meta: { title: 'CRM 儀表板' } },
  { path: '/customers', name: 'Customers', component: Customers, meta: { title: '客戶總覽' } },
  { path: '/member-tiers', name: 'MemberTiers', component: MemberTiers, meta: { title: '會員等級' } },
  { path: '/crm/channels', name: 'Channels', component: Placeholder, meta: { title: '通路主檔' } },
  { path: '/crm/collection-targets', name: 'CollectionTargets', component: Placeholder, meta: { title: '請款對象' } },
  { path: '/crm/payment-methods', name: 'PaymentMethods', component: Placeholder, meta: { title: '收款方式' } },
  
  // 託售
  { path: '/consignments', name: 'Consignments', component: Consignments, meta: { title: '託售出貨單' } },
  { path: '/consignment/returns', name: 'ConsignmentReturns', component: Placeholder, meta: { title: '託售退貨' } },
  { path: '/settlements', name: 'Settlements', component: Settlements, meta: { title: '月底結帳' } },
  
  // 銷售
  { path: '/orders', name: 'Orders', component: Orders, meta: { title: '直銷銷貨單' } },
  { path: '/sales/returns', name: 'SalesReturns', component: Returns, meta: { title: '銷售退貨' } },
  { path: '/sales/quotes', name: 'SalesQuotes', component: Quotes, meta: { title: '報價單' } },
  
  // 庫存
  { path: '/inventory', name: 'Inventory_Dashboard', component: InventoryDashboard, meta: { title: '庫存儀表板' } },
  { path: '/inventory/lots', name: 'InventoryLots', component: InventoryLots, meta: { title: 'FIFO 批次' } },
  { path: '/inventory/transactions', name: 'InventoryTransactions', component: Placeholder, meta: { title: '異動履歷' } },
  { path: '/inventory/items', name: 'InventoryItems', component: InventoryItems, meta: { title: '商品主檔' } },
  
  // 採購
  { path: '/procurement/vendors', name: 'Vendors', component: Placeholder, meta: { title: '廠商主檔' } },
  { path: '/procurement/orders', name: 'PurchaseOrders', component: PurchaseOrders, meta: { title: '採購單' } },
  { path: '/procurement/receipts', name: 'PurchaseReceipts', component: Placeholder, meta: { title: '進貨驗收' } },
  
  // 生產
  { path: '/production/boms', name: 'BOMs', component: Placeholder, meta: { title: 'BOM 主檔' } },
  { path: '/production/work-orders', name: 'WorkOrders', component: WorkOrders, meta: { title: '工單管理' } },
  { path: '/production/schedule', name: 'ProductionSchedule', component: Placeholder, meta: { title: '生產排程' } },
  
  // POS
  { path: '/pos/checkout', name: 'POSCheckout', component: POSCheckout, meta: { title: '收銀台' } },
  { path: '/pos/transactions', name: 'POSTransactions', component: POSTransactions, meta: { title: '交易記錄' } },
  { path: '/pos/shifts', name: 'POSShifts', component: Placeholder, meta: { title: '班別交接' } },
  
  // 會計
  { path: '/accounting/gl', name: 'GL', component: Placeholder, meta: { title: '總帳分錄' } },
  { path: '/accounting/ar', name: 'AR', component: Placeholder, meta: { title: '應收帳款' } },
  { path: '/accounting/ap', name: 'AP', component: Placeholder, meta: { title: '應付帳款' } },
  { path: '/accounting/periods', name: 'AccountingPeriods', component: AccountingPeriods, meta: { title: '會計期間' } },
  
  // 人事
  { path: '/hr/employees', name: 'Employees', component: Placeholder, meta: { title: '員工主檔' } },
  { path: '/hr/departments', name: 'Departments', component: Placeholder, meta: { title: '部門管理' } },
  { path: '/hr/attendance', name: 'Attendance', component: HRAttendance, meta: { title: '出勤打卡' } },
  { path: '/hr/leave', name: 'Leave', component: HRLeave, meta: { title: '請假管理' } },
  
  // 系統
  { path: '/admin', name: 'AdminData', component: DataAdmin, meta: { title: '數據管理' } },
  { path: '/research', name: 'Research', component: DatabaseResearch, meta: { title: '資料庫研究' } },
  { path: '/system/roles', name: 'Roles', component: RoleManagement, meta: { title: '角色權限' } },
  { path: '/system/settings', name: 'Settings', component: Placeholder, meta: { title: '系統設定' } },

  // Catch-all
  { path: '/:pathMatch(.*)*', name: 'NotFound', component: Placeholder, meta: { title: '找不到頁面' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Update document title
router.afterEach((to) => {
  if (to.meta.title) {
    document.title = `${to.meta.title} - DOUBLE ERP`
  }
})

export default router
