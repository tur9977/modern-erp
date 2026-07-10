<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { Chart, registerables } from 'chart.js'
import { supabase } from '../supabase'

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
  // Using dummy values for now since raw SQL aggregation isn't directly supported by simple Supabase client
  availableQty.value = 12500
  consignmentQty.value = 4200
  allocatedQty.value = 850
  onOrderQty.value = 3200
}

async function fetchKPIs() {
  try {
    const { count: pendingSO } = await supabase.from('erp_orders').select('*', { count: 'exact', head: true }).eq('status', 'DRAFT')
    kpi.value.pendingSO = pendingSO || 0

    const { count: pendingConsignment } = await supabase.from('erp_consignments').select('*', { count: 'exact', head: true }).eq('status', 'SHIPPED')
    kpi.value.pendingConsignment = pendingConsignment || 0

    const { count: pendingPO } = await supabase.from('erp_purchase_orders').select('*', { count: 'exact', head: true }).eq('status', 'PENDING')
    kpi.value.pendingPO = pendingPO || 0

    const { count: pendingWO } = await supabase.from('erp_work_orders').select('*', { count: 'exact', head: true }).in('status', ['PENDING', 'IN_PROGRESS'])
    kpi.value.pendingWO = pendingWO || 0

    kpi.value.todayPOS = 0
  } catch (e) {
    console.error('Failed to load KPIs:', e)
  }
}

async function fetchPeriodStatus() {
  try {
    const { data } = await supabase.from('erp_fiscal_periods').select('*').order('year', { ascending: false }).order('month', { ascending: false }).limit(1)
    if (data && data.length > 0) {
      periodStatus.value = data[0]
    } else {
      periodStatus.value = { year: 2026, month: 7, closed: false }
    }
  } catch (e) {
    console.error('Failed to load period status:', e)
  }
}

async function fetchARAging() {
  // Mock data for AR aging chart
  arAgingData.value = {
    not_due: { amount: 150000, count: 12 },
    '0_30': { amount: 45000, count: 5 },
    '31_60': { amount: 12000, count: 2 },
    '61_90': { amount: 5000, count: 1 },
    '90_plus': { amount: 2000, count: 1 }
  }
  await nextTick()
  renderARChart()
}

async function fetchMonthlyPL() {
  // Mock data for P&L chart
  monthlyData.value = [
    { month: 1, revenue: 120000, expense: 80000, profit: 40000 },
    { month: 2, revenue: 135000, expense: 85000, profit: 50000 },
    { month: 3, revenue: 140000, expense: 90000, profit: 50000 },
    { month: 4, revenue: 160000, expense: 95000, profit: 65000 },
    { month: 5, revenue: 155000, expense: 92000, profit: 63000 },
    { month: 6, revenue: 180000, expense: 100000, profit: 80000 },
    { month: 7, revenue: 200000, expense: 110000, profit: 90000 }
  ]
  await nextTick()
  renderPLChart()
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
