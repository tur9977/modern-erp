<template>
  <div class="dashboard-container animate-fade-in">
    <div class="page-header">
      <div>
        <h1>🤖 帳務心智流程圖</h1>
        <p class="subtitle">DOUBLE ERP 企業資源規劃與風控總覽</p>
      </div>
    </div>

    <!-- KPI Summary Cards -->
    <div class="kpi-row">
      <div class="glass-card stat-card">
        <span class="stat-label">公司可用在庫 (Available)</span>
        <span class="stat-value" :style="availableQty > 0 ? 'color: #6366f1;' : 'color: #888;'">{{ availableQty }} <span style="font-size: 1rem; font-weight: normal;">件</span></span>
        <span class="stat-desc">總公司與直營門市可即時銷貨庫存<span v-if="loading"> (載入中...)</span></span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">通路託售在庫 (Consignment)</span>
        <span class="stat-value" style="color: #f59e0b;">{{ consignmentQty }} <span style="font-size: 1rem; font-weight: normal;">件</span></span>
        <span class="stat-desc">羈押在各加盟代理通路尚未結帳在庫</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">線上鎖定庫存 (Allocated)</span>
        <span class="stat-value" style="color: #ef4444;">{{ allocatedQty }} <span style="font-size: 1rem; font-weight: normal;">件</span></span>
        <span class="stat-desc">電商已付款待打包發貨鎖定數量</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">委外在途在庫 (On Order)</span>
        <span class="stat-value" style="color: #10b981;">{{ onOrderQty }} <span style="font-size: 1rem; font-weight: normal;">件</span></span>
        <span class="stat-desc">工單已開、工廠在途尚未入庫數量</span>
      </div>
    </div>

    <!-- Full Asset Formula Block -->
    <div class="glass-card asset-formula-card">
      <h2 style="display: flex; align-items: center; gap: 0.5rem;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        全資產公式總庫存計量
      </h2>
      <div style="display: flex; flex-wrap: wrap; align-items: center; gap: 1.5rem; margin-top: 1rem;">
        <div style="font-size: 2.2rem; font-weight: 700; color: #fff;">{{ totalAssetStock }} <span style="font-size: 1.2rem; font-weight: 500; color: var(--text-muted);">件</span></div>
        <div style="font-size: 1.1rem; color: var(--text-muted); font-family: monospace;">
          = {{ availableQty }} (Available) + {{ consignmentQty }} (Consignment) + {{ onOrderQty }} (On Order) - {{ allocatedQty }} (Allocated)
        </div>
      </div>
    </div>

    <!-- Mind Map Flow Diagram -->
    <div class="glass-card mindmap-card">
      <h2>📊 核心帳務心智流程圖</h2>
      <p class="mindmap-hint">點擊任一流程節點，進入該系統處理業務</p>
      <div class="mindmap-grid">
        <!-- Row 1: Main flows -->
        <div class="mindmap-row">
          <!-- 直營銷貨 SO -->
          <div class="flow-node flow-so" @click="navigateTo('/orders')">
            <div class="flow-icon">🛒</div>
            <div class="flow-info">
              <div class="flow-title">直營銷貨</div>
              <div class="flow-subtitle">Sales Orders</div>
            </div>
            <div class="kpi-badge" v-if="kpi.pendingSO > 0">
              <span class="badge badge-danger">{{ kpi.pendingSO }}</span>
            </div>
            <div class="flow-status" :class="kpi.pendingSO > 0 ? 'has-pending' : 'all-clear'">
              {{ kpi.pendingSO > 0 ? '待出貨 ' + kpi.pendingSO + ' 單' : '✓ 已清' }}
            </div>
          </div>

          <!-- 託售對帳 -->
          <div class="flow-connector">→</div>
          <div class="flow-node flow-consignment" @click="navigateTo('/consignments')">
            <div class="flow-icon">🤝</div>
            <div class="flow-info">
              <div class="flow-title">託售對帳</div>
              <div class="flow-subtitle">Consignments</div>
            </div>
            <div class="kpi-badge" v-if="kpi.pendingConsignment > 0">
              <span class="badge badge-warning">{{ kpi.pendingConsignment }}</span>
            </div>
            <div class="flow-status" :class="kpi.pendingConsignment > 0 ? 'has-pending' : 'all-clear'">
              {{ kpi.pendingConsignment > 0 ? '待結帳 ' + kpi.pendingConsignment + ' 單' : '✓ 已清' }}
            </div>
          </div>

          <!-- 採購付款 -->
          <div class="flow-connector">→</div>
          <div class="flow-node flow-po" @click="navigateTo('/purchase-orders')">
            <div class="flow-icon">🛍️</div>
            <div class="flow-info">
              <div class="flow-title">採購付款</div>
              <div class="flow-subtitle">Purchase Orders</div>
            </div>
            <div class="kpi-badge" v-if="kpi.pendingPO > 0">
              <span class="badge badge-warning">{{ kpi.pendingPO }}</span>
            </div>
            <div class="flow-status" :class="kpi.pendingPO > 0 ? 'has-pending' : 'all-clear'">
              {{ kpi.pendingPO > 0 ? '待驗收 ' + kpi.pendingPO + ' 單' : '✓ 已清' }}
            </div>
          </div>
        </div>

        <!-- Center Connector -->
        <div class="mindmap-center-connector">
          <div class="center-icon">💰</div>
          <div class="center-label">財務結算</div>
          <div class="center-sublabel">AR / 月結</div>
        </div>

        <!-- Row 2: WO + POS -->
        <div class="mindmap-row mindmap-row-bottom">
          <!-- 生產製造 -->
          <div class="flow-node flow-wo" @click="navigateTo('/work-orders')">
            <div class="flow-icon">🏭</div>
            <div class="flow-info">
              <div class="flow-title">生產製造</div>
              <div class="flow-subtitle">Work Orders</div>
            </div>
            <div class="kpi-badge" v-if="kpi.pendingWO > 0">
              <span class="badge badge-info">{{ kpi.pendingWO }}</span>
            </div>
            <div class="flow-status" :class="kpi.pendingWO > 0 ? 'has-pending' : 'all-clear'">
              {{ kpi.pendingWO > 0 ? '待完工 ' + kpi.pendingWO + ' 單' : '✓ 已清' }}
            </div>
          </div>

          <div class="flow-connector">←</div>

          <!-- POS 收銀 -->
          <div class="flow-node flow-pos" @click="navigateTo('/pos-checkout')">
            <div class="flow-icon">💵</div>
            <div class="flow-info">
              <div class="flow-title">門市收銀</div>
              <div class="flow-subtitle">POS Checkout</div>
            </div>
            <div class="kpi-badge" v-if="kpi.todayPOS > 0">
              <span class="badge badge-success">{{ kpi.todayPOS }}</span>
            </div>
            <div class="flow-status all-clear">
              今日 {{ kpi.todayPOS }} 筆交易
            </div>
          </div>
        </div>
      </div>

      <!-- Period Status -->
      <div class="period-status-bar" v-if="periodStatus">
        <span class="period-label">📅 帳期狀態：</span>
        <span class="badge" :class="periodStatus.closed ? 'badge-success' : 'badge-warning'">
          {{ periodStatus.year }}/{{ String(periodStatus.month).padStart(2, '0') }}
          {{ periodStatus.closed ? ' 已關帳' : ' 未關帳' }}
        </span>
        <button v-if="!periodStatus.closed" class="btn btn-primary btn-sm" @click="navigateTo('/accounting/periods')">
          前往月結 →
        </button>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="charts-row">
      <!-- AR Aging Pie Chart -->
      <div class="glass-card chart-card">
        <h2>📒 AR 應收帳款帳齡分析</h2>
        <div class="chart-container">
          <canvas ref="arChartCanvas"></canvas>
        </div>
        <div class="ar-legend" v-if="arAgingData">
          <div class="legend-item" v-for="item in arLegendItems" :key="item.label">
            <span class="legend-dot" :style="{ background: item.color }"></span>
            <span class="legend-label">{{ item.label }}</span>
            <span class="legend-value">{{ item.amount }}</span>
            <span class="legend-count">{{ item.count }} 筆</span>
          </div>
        </div>
      </div>

      <!-- Monthly P&L Line Chart -->
      <div class="glass-card chart-card">
        <h2>📈 月度損益趨勢</h2>
        <div class="chart-container">
          <canvas ref="plChartCanvas"></canvas>
        </div>
        <div class="pl-summary" v-if="monthlyData">
          <div class="pl-stat">
            <span class="pl-stat-label">年度總營收</span>
            <span class="pl-stat-value" style="color: #4A7C59;">{{ formatCurrency(totalRevenue) }}</span>
          </div>
          <div class="pl-stat">
            <span class="pl-stat-label">年度總費用</span>
            <span class="pl-stat-value" style="color: #A63D40;">{{ formatCurrency(totalExpense) }}</span>
          </div>
          <div class="pl-stat">
            <span class="pl-stat-label">年度淨損益</span>
            <span class="pl-stat-value" :style="{ color: netProfit >= 0 ? '#4A7C59' : '#A63D40' }">
              {{ formatCurrency(netProfit) }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Risk & Replenish Row -->
    <div class="grid-cols-2">
      <!-- Risk Settings -->
      <div class="glass-card">
        <h2>加盟商風控狀態監視</h2>
        <table>
          <thead>
            <tr>
              <th>代理商</th>
              <th>資產額度</th>
              <th>安全周轉天數</th>
              <th>風控警示</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>託售代理商甲 (北部)</td>
              <td>$1,000 / $1,500</td>
              <td>60 天</td>
              <td><span class="badge badge-success">正常 (綠燈)</span></td>
            </tr>
            <tr>
              <td>連鎖經銷商乙 (中部)</td>
              <td>$4,200 / $3,000</td>
              <td>60 天</td>
              <td><span class="badge badge-danger">額度超標 (紅燈)</span></td>
            </tr>
            <tr>
              <td>蝦皮合作窗口丙</td>
              <td>$800 / $2,000</td>
              <td>30 天</td>
              <td><span class="badge badge-warning">呆滯未結 (黃燈)</span></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- EOL / Replenish -->
      <div class="glass-card">
        <h2>智能補貨與商品狀態</h2>
        <table>
          <thead>
            <tr>
              <th>商品 SKU</th>
              <th>日均銷量</th>
              <th>安全存量點 (ROP)</th>
              <th>採購推薦</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>BINDER-01 (經典款)</td>
              <td>2.4 件/日</td>
              <td>53 件</td>
              <td><span class="badge badge-success">無需採購 (充足)</span></td>
            </tr>
            <tr>
              <td>BINDER-02 (網眼透氣)</td>
              <td>8.1 件/日</td>
              <td>178 件</td>
              <td><span class="badge badge-danger">推薦採購 +150 件</span></td>
            </tr>
            <tr>
              <td>BINDER-03 (拉鍊款)</td>
              <td>-</td>
              <td>-</td>
              <td><span class="badge badge-muted">EOL 逆向召回中</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const router = useRouter()

// Inventory KPIs
const availableQty = ref(0)
const consignmentQty = ref(0)
const allocatedQty = ref(0)
const onOrderQty = ref(0)
const loading = ref(true)

// Mind map KPIs
const kpi = ref({
  pendingSO: 0,
  pendingConsignment: 0,
  pendingPO: 0,
  pendingWO: 0,
  todayPOS: 0
})

// Period status
const periodStatus = ref(null)

// AR Aging data
const arAgingData = ref(null)
const arChartCanvas = ref(null)
let arChartInstance = null

// Monthly P&L data
const monthlyData = ref(null)
const plChartCanvas = ref(null)
let plChartInstance = null

const totalAssetStock = computed(() => {
  return availableQty.value + consignmentQty.value + onOrderQty.value - allocatedQty.value
})

const arLegendItems = computed(() => {
  if (!arAgingData.value) return []
  const d = arAgingData.value
  const colors = ['#4A7C59', '#8B6914', '#B8860B', '#D97706', '#A63D40']
  return [
    { label: '未逾期', color: colors[0], amount: formatCurrency(d.not_due?.amount || 0), count: d.not_due?.count || 0 },
    { label: '0-30天', color: colors[1], amount: formatCurrency(d['0_30']?.amount || 0), count: d['0_30']?.count || 0 },
    { label: '31-60天', color: colors[2], amount: formatCurrency(d['31_60']?.amount || 0), count: d['31_60']?.count || 0 },
    { label: '61-90天', color: colors[3], amount: formatCurrency(d['61_90']?.amount || 0), count: d['61_90']?.count || 0 },
    { label: '90天以上', color: colors[4], amount: formatCurrency(d['90_plus']?.amount || 0), count: d['90_plus']?.count || 0 }
  ]
})

const totalRevenue = computed(() => {
  if (!monthlyData.value) return 0
  return monthlyData.value.reduce((sum, m) => sum + (m.revenue || 0), 0)
})

const totalExpense = computed(() => {
  if (!monthlyData.value) return 0
  return monthlyData.value.reduce((sum, m) => sum + (m.expense || 0), 0)
})

const netProfit = computed(() => totalRevenue.value - totalExpense.value)

function formatCurrency(val) {
  if (val == null) return '$0'
  return '$' + Number(val).toLocaleString('zh-TW')
}

function navigateTo(path) {
  router.push(path)
}

async function fetchInventorySummary() {
  try {
    const res = await apiClient.post('/db/query', {
      sql: "SELECT SUM(available_qty) as available, SUM(consignment_qty) as consignment, SUM(allocated_qty) as allocated, SUM(on_order_qty) as on_order FROM inventory"
    })
    const data = res.data
    if (data.rows && data.rows.length > 0) {
      const row = data.rows[0]
      availableQty.value = Number(row.available) || 0
      consignmentQty.value = Number(row.consignment) || 0
      allocatedQty.value = Number(row.allocated) || 0
      onOrderQty.value = Number(row.on_order) || 0
    }
  } catch (e) {
    console.error('Failed to load inventory:', e)
  }
}

async function fetchKPIs() {
  try {
    // Pending SO (DRAFT status = awaiting shipment)
    const soRes = await apiClient.get('/orders?status=DRAFT')
    kpi.value.pendingSO = Array.isArray(soRes.data) ? soRes.data.length : 0

    // Pending Consignment (SHIPPED status = out, awaiting settlement)
    const conRes = await apiClient.get('/consignments?status=SHIPPED')
    kpi.value.pendingConsignment = Array.isArray(conRes.data) ? conRes.data.length : 0

    // Pending PO (PENDING status = awaiting receipt)
    const poRes = await apiClient.get('/purchase-orders?status=PENDING')
    kpi.value.pendingPO = Array.isArray(poRes.data) ? poRes.data.length : 0

    // Pending WO (PENDING or IN_PROGRESS)
    const woRes = await apiClient.get('/work-orders?status=PENDING,IN_PROGRESS')
    kpi.value.pendingWO = Array.isArray(woRes.data) ? woRes.data.length : 0

    // Today's POS transactions
    const today = new Date().toISOString().split('T')[0]
    const posRes = await apiClient.get(`/pos/transactions?date=${today}`)
    kpi.value.todayPOS = Array.isArray(posRes.data) ? posRes.data.length : 0
  } catch (e) {
    console.error('Failed to load KPIs:', e)
  }
}

async function fetchPeriodStatus() {
  try {
    const res = await apiClient.get('/accounting/periods')
    const periods = res.data
    if (Array.isArray(periods) && periods.length > 0) {
      const latest = periods.sort((a, b) => {
        if (b.year !== a.year) return b.year - a.year
        return b.month - a.month
      })[0]
      periodStatus.value = latest
    }
  } catch (e) {
    console.error('Failed to load period status:', e)
  }
}

async function fetchARAging() {
  try {
    const res = await apiClient.get('/accounting/ar/aging')
    arAgingData.value = res.data
    await nextTick()
    renderARChart()
  } catch (e) {
    console.error('Failed to load AR aging:', e)
  }
}

async function fetchMonthlyPL() {
  try {
    const year = new Date().getFullYear()
    const res = await apiClient.get(`/accounting/gl/monthly-summary?year=${year}`)
    monthlyData.value = res.data
    await nextTick()
    renderPLChart()
  } catch (e) {
    console.error('Failed to load monthly P&L:', e)
  }
}

function renderARChart() {
  if (!arChartCanvas.value || !arAgingData.value) return
  if (arChartInstance) arChartInstance.destroy()

  const d = arAgingData.value
  const labels = ['未逾期', '0-30天', '31-60天', '61-90天', '90天以上']
  const data = [
    d.not_due?.amount || 0,
    d['0_30']?.amount || 0,
    d['31_60']?.amount || 0,
    d['61_90']?.amount || 0,
    d['90_plus']?.amount || 0
  ]
  const colors = ['#4A7C59', '#8B6914', '#B8860B', '#D97706', '#A63D40']

  arChartInstance = new Chart(arChartCanvas.value, {
    type: 'doughnut',
    data: {
      labels,
      datasets: [{
        data,
        backgroundColor: colors,
        borderColor: '#FAF7F2',
        borderWidth: 3
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => ' $' + Number(ctx.raw).toLocaleString('zh-TW')
          }
        }
      }
    }
  })
}

function renderPLChart() {
  if (!plChartCanvas.value || !monthlyData.value) return
  if (plChartInstance) plChartInstance.destroy()

  const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
  const revenue = monthlyData.value.map(m => m.revenue || 0)
  const expense = monthlyData.value.map(m => m.expense || 0)
  const profit = monthlyData.value.map(m => m.profit || 0)

  plChartInstance = new Chart(plChartCanvas.value, {
    type: 'line',
    data: {
      labels: months,
      datasets: [
        {
          label: '營收',
          data: revenue,
          borderColor: '#4A7C59',
          backgroundColor: 'rgba(74, 124, 89, 0.1)',
          fill: true,
          tension: 0.4
        },
        {
          label: '費用',
          data: expense,
          borderColor: '#A63D40',
          backgroundColor: 'rgba(166, 61, 64, 0.1)',
          fill: true,
          tension: 0.4
        },
        {
          label: '淨損益',
          data: profit,
          borderColor: '#8B6914',
          backgroundColor: 'transparent',
          borderDash: [5, 5],
          tension: 0.4
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          position: 'bottom',
          labels: { color: '#6B635B', font: { family: 'Outfit' } }
        },
        tooltip: {
          callbacks: {
            label: (ctx) => ' ' + ctx.dataset.label + ': $' + Number(ctx.raw).toLocaleString('zh-TW')
          }
        }
      },
      scales: {
        x: {
          ticks: { color: '#9A9189' },
          grid: { color: 'rgba(139, 105, 20, 0.08)' }
        },
        y: {
          ticks: {
            color: '#9A9189',
            callback: (v) => '$' + (v >= 1000 ? (v / 1000).toFixed(0) + 'k' : v)
          },
          grid: { color: 'rgba(139, 105, 20, 0.08)' }
        }
      }
    }
  })
}

onMounted(async () => {
  loading.value = true
  await Promise.all([
    fetchInventorySummary(),
    fetchKPIs(),
    fetchPeriodStatus(),
    fetchARAging(),
    fetchMonthlyPL()
  ])
  loading.value = false
})
</script>

<style scoped>
.dashboard-container {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-glass);
}

.page-header h1 {
  font-size: 2rem;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 0.25rem;
}

.subtitle {
  color: var(--text-secondary);
  font-size: 0.95rem;
  margin-bottom: 0;
}

/* KPI Row */
.kpi-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.25rem;
  margin-bottom: 1.5rem;
}

.stat-card {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 1.25rem;
  background: var(--bg-card);
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-card);
}

.stat-label {
  font-size: 0.75rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: 1.75rem;
  font-weight: 700;
  color: var(--text-primary);
}

.stat-desc {
  font-size: 0.8rem;
  color: var(--text-secondary);
}

/* Asset Formula */
.asset-formula-card {
  margin-bottom: 1.5rem;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.15) 0%, rgba(6, 182, 212, 0.1) 100%);
}

/* Mind Map */
.mindmap-card {
  margin-bottom: 1.5rem;
}

.mindmap-hint {
  color: var(--text-muted);
  font-size: 0.85rem;
  margin-bottom: 1.5rem;
  margin-top: -0.5rem;
}

.mindmap-grid {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  align-items: center;
}

.mindmap-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  width: 100%;
  justify-content: center;
}

.mindmap-row-bottom {
  margin-top: -1rem;
}

.flow-node {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1.25rem 1.5rem;
  background: var(--bg-card);
  border: 2px solid var(--border-glass);
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  min-width: 130px;
  position: relative;
}

.flow-node:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(139, 105, 20, 0.15);
}

.flow-node.flow-so { border-color: rgba(99, 102, 241, 0.3); }
.flow-node.flow-so:hover { border-color: #6366f1; background: rgba(99, 102, 241, 0.05); }

.flow-node.flow-consignment { border-color: rgba(245, 158, 11, 0.3); }
.flow-node.flow-consignment:hover { border-color: #f59e0b; background: rgba(245, 158, 11, 0.05); }

.flow-node.flow-po { border-color: rgba(16, 185, 129, 0.3); }
.flow-node.flow-po:hover { border-color: #10b981; background: rgba(16, 185, 129, 0.05); }

.flow-node.flow-wo { border-color: rgba(91, 123, 138, 0.3); }
.flow-node.flow-wo:hover { border-color: #5B7B8A; background: rgba(91, 123, 138, 0.05); }

.flow-node.flow-pos { border-color: rgba(139, 105, 20, 0.3); }
.flow-node.flow-pos:hover { border-color: #8B6914; background: rgba(139, 105, 20, 0.05); }

.flow-icon {
  font-size: 2rem;
}

.flow-info {
  text-align: center;
}

.flow-title {
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--text-primary);
}

.flow-subtitle {
  font-size: 0.75rem;
  color: var(--text-muted);
}

.flow-status {
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.2rem 0.6rem;
  border-radius: 9999px;
}

.flow-status.has-pending {
  background: rgba(166, 61, 64, 0.12);
  color: var(--color-danger);
}

.flow-status.all-clear {
  background: rgba(74, 124, 89, 0.12);
  color: var(--color-success);
}

.flow-connector {
  font-size: 1.5rem;
  color: var(--text-muted);
  font-weight: 300;
}

.mindmap-center-connector {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  padding: 1rem 2rem;
  background: linear-gradient(135deg, rgba(139, 105, 20, 0.15) 0%, rgba(6, 182, 212, 0.1) 100%);
  border-radius: 16px;
  border: 2px solid rgba(139, 105, 20, 0.2);
}

.center-icon {
  font-size: 2rem;
}

.center-label {
  font-weight: 700;
  font-size: 1rem;
  color: var(--text-primary);
}

.center-sublabel {
  font-size: 0.75rem;
  color: var(--text-muted);
}

/* Period Status Bar */
.period-status-bar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-top: 1.5rem;
  padding: 0.75rem 1rem;
  background: rgba(139, 105, 20, 0.06);
  border-radius: 8px;
  border: 1px solid var(--border-glass);
}

.period-label {
  font-size: 0.85rem;
  color: var(--text-secondary);
  font-weight: 500;
}

.btn-sm {
  padding: 0.4rem 0.8rem;
  font-size: 0.8rem;
  margin-left: auto;
}

/* Charts Row */
.charts-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.25rem;
  margin-bottom: 1.5rem;
}

.chart-card h2 {
  margin-bottom: 1rem;
}

.chart-container {
  position: relative;
  height: 220px;
}

/* AR Legend */
.ar-legend {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 0.85rem;
}

.legend-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.legend-label {
  color: var(--text-secondary);
  min-width: 70px;
}

.legend-value {
  font-weight: 600;
  color: var(--text-primary);
  margin-left: auto;
}

.legend-count {
  color: var(--text-muted);
  font-size: 0.8rem;
}

/* P&L Summary */
.pl-summary {
  display: flex;
  gap: 1.5rem;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--border-glass);
}

.pl-stat {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.pl-stat-label {
  font-size: 0.75rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.pl-stat-value {
  font-size: 1.1rem;
  font-weight: 700;
}

/* Grid cols 2 */
.grid-cols-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.25rem;
  margin-bottom: 1.5rem;
}

@media (max-width: 1024px) {
  .kpi-row { grid-template-columns: repeat(2, 1fr); }
  .charts-row { grid-template-columns: 1fr; }
  .grid-cols-2 { grid-template-columns: 1fr; }
  .mindmap-row { flex-wrap: wrap; }
}
</style>
