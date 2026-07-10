<template>
  <div class="animate-fade-in">
    <h1>POS 交易記錄</h1>
    <p class="subtitle">DOUBLE ERP 銷售交易歷史查詢</p>

    <!-- Error Message -->
    <div v-if="errorMessage" class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
      {{ errorMessage }}
    </div>

    <!-- Filters Section -->
    <div class="glass-card filter-section">
      <h3>搜尋條件</h3>
      <div class="filter-grid">
        <div class="filter-group">
          <label>起始日期</label>
          <input type="date" v-model="filters.startDate" @change="applyFilters" />
        </div>
        <div class="filter-group">
          <label>結束日期</label>
          <input type="date" v-model="filters.endDate" @change="applyFilters" />
        </div>
        <div class="filter-group">
          <label>付款方式</label>
          <select v-model="filters.paymentMethod" @change="applyFilters">
            <option value="">全部</option>
            <option value="cash">現金</option>
            <option value="credit">信用卡</option>
            <option value="linepay">LINE Pay</option>
          </select>
        </div>
        <div class="filter-group">
          <label>交易狀態</label>
          <select v-model="filters.status" @change="applyFilters">
            <option value="">全部</option>
            <option value="completed">已完成</option>
            <option value="pending">處理中</option>
            <option value="refunded">已退款</option>
            <option value="cancelled">已取消</option>
          </select>
        </div>
        <div class="filter-group">
          <label>關鍵字搜尋</label>
          <input type="text" v-model="filters.keyword" placeholder="交易編號 / 客戶名稱" @input="debounceSearch" />
        </div>
        <div class="filter-group">
          <label>　</label>
          <button class="btn btn-secondary" @click="resetFilters">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/></svg>
            重置
          </button>
        </div>
      </div>
      <div class="quick-date-btns">
        <button class="btn btn-outline btn-sm" @click="setQuickDate('today')">今天</button>
        <button class="btn btn-outline btn-sm" @click="setQuickDate('yesterday')">昨天</button>
        <button class="btn btn-outline btn-sm" @click="setQuickDate('last7days')">最近7天</button>
        <button class="btn btn-outline btn-sm" @click="setQuickDate('last30days')">最近30天</button>
        <button class="btn btn-outline btn-sm" @click="setQuickDate('thisMonth')">本月</button>
        <button class="btn btn-outline btn-sm" @click="setQuickDate('lastMonth')">上月</button>
      </div>
    </div>

    <!-- Stats Summary -->
    <div class="stats-grid">
      <div class="glass-card stat-card">
        <span class="stat-label">交易筆數</span>
        <span class="stat-value">{{ stats.totalCount }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">交易總額</span>
        <span class="stat-value" style="color: #10b981;">${{ stats.totalAmount.toLocaleString() }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">平均客單價</span>
        <span class="stat-value" style="color: #6366f1;">${{ stats.avgAmount.toLocaleString() }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">現金交易</span>
        <span class="stat-value">${{ stats.cashAmount.toLocaleString() }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">信用卡</span>
        <span class="stat-value">${{ stats.creditAmount.toLocaleString() }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">LINE Pay</span>
        <span class="stat-value">${{ stats.linepayAmount.toLocaleString() }}</span>
      </div>
    </div>

    <!-- Transactions Table -->
    <div class="glass-card">
      <div class="table-header">
        <h2>交易明細</h2>
        <div class="table-actions">
          <button class="btn btn-outline" @click="exportCSV" :disabled="transactions.length === 0">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
            匯出 CSV
          </button>
          <button class="btn btn-secondary" @click="loadTransactions" :disabled="loading">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            重新整理
          </button>
        </div>
      </div>

      <div v-if="loading" class="loading-state">
        <svg class="spinner" xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
        <p>載入中...</p>
      </div>

      <table v-else>
        <thead>
          <tr>
            <th @click="sortBy('id')" class="sortable">
              交易編號
              <span v-if="sortField === 'id'">{{ sortDir === 'asc' ? '↑' : '↓' }}</span>
            </th>
            <th @click="sortBy('created_at')" class="sortable">
              交易時間
              <span v-if="sortField === 'created_at'">{{ sortDir === 'asc' ? '↑' : '↓' }}</span>
            </th>
            <th>客戶</th>
            <th>商品</th>
            <th @click="sortBy('subtotal')" class="sortable">
              小計
              <span v-if="sortField === 'subtotal'">{{ sortDir === 'asc' ? '↑' : '↓' }}</span>
            </th>
            <th @click="sortBy('tax')" class="sortable">
              稅金
              <span v-if="sortField === 'tax'">{{ sortDir === 'asc' ? '↑' : '↓' }}</span>
            </th>
            <th @click="sortBy('total')" class="sortable">
              合計
              <span v-if="sortField === 'total'">{{ sortDir === 'asc' ? '↑' : '↓' }}</span>
            </th>
            <th>付款方式</th>
            <th>找零</th>
            <th>狀態</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="txn in sortedTransactions" :key="txn.id">
            <tr class="transaction-row" :class="{ expanded: expandedTxnId === txn.id }" @click="toggleExpand(txn.id)">
              <td><span class="txn-id">{{ txn.id }}</span></td>
              <td>{{ formatDateTime(txn.created_at) }}</td>
              <td>{{ txn.customer_name || '一般客戶' }}<br><span class="text-muted text-sm">{{ txn.customer_phone || '' }}</span></td>
              <td>{{ txn.item_count || txn.items?.length || 0 }} 項</td>
              <td>${{ txn.subtotal?.toLocaleString() }}</td>
              <td>${{ txn.tax?.toLocaleString() }}</td>
              <td class="amount">${{ txn.total?.toLocaleString() }}</td>
              <td>
                <span :class="'payment-badge ' + txn.payment_method">
                  {{ paymentMethodLabel(txn.payment_method) }}
                </span>
              </td>
              <td>${{ txn.change?.toLocaleString() || '0' }}</td>
              <td>
                <span :class="'badge badge-' + statusColor(txn.status)">{{ statusLabel(txn.status) }}</span>
              </td>
              <td @click.stop>
                <button class="btn-icon" title="查看詳情" @click="viewDetails(txn)">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
                <button v-if="txn.status === 'completed'" class="btn-icon btn-warning" title="退款" @click="refundTransaction(txn)">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>
                </button>
              </td>
            </tr>
            <!-- Expanded Detail Row -->
            <tr v-if="expandedTxnId === txn.id" class="detail-row">
              <td colspan="11">
                <div class="detail-content">
                  <h4>交易明細 - {{ txn.id }}</h4>
                  <table class="detail-table">
                    <thead>
                      <tr>
                        <th>SKU</th>
                        <th>商品名稱</th>
                        <th>單價</th>
                        <th>數量</th>
                        <th>小計</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="item in txn.items" :key="item.sku">
                        <td><span class="sku-tag">{{ item.sku }}</span></td>
                        <td>{{ item.name }}</td>
                        <td>${{ item.unit_price?.toLocaleString() }}</td>
                        <td>{{ item.quantity }}</td>
                        <td>${{ (item.unit_price * item.quantity).toLocaleString() }}</td>
                      </tr>
                    </tbody>
                  </table>
                  <div class="detail-summary">
                    <div>小計: ${{ txn.subtotal?.toLocaleString() }}</div>
                    <div>稅金: ${{ txn.tax?.toLocaleString() }}</div>
                    <div class="total">合計: ${{ txn.total?.toLocaleString() }}</div>
                    <div v-if="txn.payment_method === 'cash'">收到: ${{ txn.cash_received?.toLocaleString() }}</div>
                    <div v-if="txn.payment_method === 'cash'">找零: ${{ txn.change?.toLocaleString() }}</div>
                  </div>
                </div>
              </td>
            </tr>
          </template>
          <tr v-if="transactions.length === 0 && !loading">
            <td colspan="11" class="empty-row">
              <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                <p>目前沒有符合條件的交易記錄</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div class="pagination" v-if="totalPages > 1">
        <button class="btn btn-outline" @click="goToPage(1)" :disabled="currentPage === 1">«</button>
        <button class="btn btn-outline" @click="goToPage(currentPage - 1)" :disabled="currentPage === 1">‹</button>
        <span class="page-info">第 {{ currentPage }} 頁 / 共 {{ totalPages }} 頁</span>
        <button class="btn btn-outline" @click="goToPage(currentPage + 1)" :disabled="currentPage === totalPages">›</button>
        <button class="btn btn-outline" @click="goToPage(totalPages)" :disabled="currentPage === totalPages">»</button>
      </div>
    </div>

    <!-- Transaction Detail Modal -->
    <div v-if="showDetailModal" class="modal-overlay" @click.self="showDetailModal = false">
      <div class="modal-content glass-card">
        <div class="modal-header">
          <h2>交易詳情 - {{ selectedTransaction?.id }}</h2>
          <button class="btn-icon" @click="showDetailModal = false">×</button>
        </div>
        <div class="modal-body">
          <div class="detail-section">
            <h4>基本資訊</h4>
            <div class="detail-grid">
              <div class="detail-item"><label>交易編號:</label><span>{{ selectedTransaction?.id }}</span></div>
              <div class="detail-item"><label>交易時間:</label><span>{{ formatDateTime(selectedTransaction?.created_at) }}</span></div>
              <div class="detail-item"><label>客戶:</label><span>{{ selectedTransaction?.customer_name || '一般客戶' }}</span></div>
              <div class="detail-item"><label>付款方式:</label><span>{{ paymentMethodLabel(selectedTransaction?.payment_method) }}</span></div>
              <div class="detail-item"><label>狀態:</label><span :class="'badge badge-' + statusColor(selectedTransaction?.status)">{{ statusLabel(selectedTransaction?.status) }}</span></div>
            </div>
          </div>
          <div class="detail-section">
            <h4>商品明細</h4>
            <table class="detail-table">
              <thead><tr><th>SKU</th><th>名稱</th><th>單價</th><th>數量</th><th>小計</th></tr></thead>
              <tbody>
                <tr v-for="item in selectedTransaction?.items" :key="item.sku">
                  <td><span class="sku-tag">{{ item.sku }}</span></td>
                  <td>{{ item.name }}</td>
                  <td>${{ item.unit_price?.toLocaleString() }}</td>
                  <td>{{ item.quantity }}</td>
                  <td>${{ (item.unit_price * item.quantity).toLocaleString() }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="detail-section">
            <h4>金額汇总</h4>
            <div class="summary-box">
              <div class="summary-row"><span>小計</span><span>${{ selectedTransaction?.subtotal?.toLocaleString() }}</span></div>
              <div class="summary-row"><span>稅金 (5%)</span><span>${{ selectedTransaction?.tax?.toLocaleString() }}</span></div>
              <div class="summary-row total"><span>合計</span><span>${{ selectedTransaction?.total?.toLocaleString() }}</span></div>
              <div v-if="selectedTransaction?.payment_method === 'cash'" class="summary-row"><span>收到金額</span><span>${{ selectedTransaction?.cash_received?.toLocaleString() }}</span></div>
              <div v-if="selectedTransaction?.payment_method === 'cash'" class="summary-row"><span>找零</span><span>${{ selectedTransaction?.change?.toLocaleString() }}</span></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const transactions = ref([]);
const loading = ref(false);
const errorMessage = ref('');

const filters = ref({
  startDate: '',
  endDate: '',
  paymentMethod: '',
  status: '',
  keyword: ''
});

const sortField = ref('created_at');
const sortDir = ref('desc');

const currentPage = ref(1);
const pageSize = ref(20);
const expandedTxnId = ref(null);
const showDetailModal = ref(false);
const selectedTransaction = ref(null);

let searchTimeout = null;

const stats = computed(() => {
  const all = transactions.value;
  const completed = all.filter(t => t.status === 'completed');
  const cashTotal = completed.filter(t => t.payment_method === 'cash').reduce((s, t) => s + (t.total || 0), 0);
  const creditTotal = completed.filter(t => t.payment_method === 'credit').reduce((s, t) => s + (t.total || 0), 0);
  const linepayTotal = completed.filter(t => t.payment_method === 'linepay').reduce((s, t) => s + (t.total || 0), 0);
  const totalAmount = completed.reduce((s, t) => s + (t.total || 0), 0);
  return {
    totalCount: all.length,
    totalAmount,
    avgAmount: all.length > 0 ? Math.round(totalAmount / all.length) : 0,
    cashAmount: cashTotal,
    creditAmount: creditTotal,
    linepayAmount: linepayTotal
  };
});

const filteredTransactions = computed(() => {
  let result = [...transactions.value];
  if (filters.value.keyword) {
    const kw = filters.value.keyword.toLowerCase();
    result = result.filter(t =>
      (t.id && t.id.toLowerCase().includes(kw)) ||
      (t.customer_name && t.customer_name.toLowerCase().includes(kw))
    );
  }
  return result;
});

const sortedTransactions = computed(() => {
  const data = [...filteredTransactions.value];
  data.sort((a, b) => {
    let aVal = a[sortField.value];
    let bVal = b[sortField.value];
    if (typeof aVal === 'string') aVal = aVal.toLowerCase();
    if (typeof bVal === 'string') bVal = bVal.toLowerCase();
    if (aVal < bVal) return sortDir.value === 'asc' ? -1 : 1;
    if (aVal > bVal) return sortDir.value === 'asc' ? 1 : -1;
    return 0;
  });
  return data;
});

const totalPages = computed(() => Math.ceil(filteredTransactions.value.length / pageSize.value));

function setQuickDate(preset) {
  const now = new Date();
  const fmt = d => d.toISOString().split('T')[0];
  switch (preset) {
    case 'today':
      filters.value.startDate = fmt(now);
      filters.value.endDate = fmt(now);
      break;
    case 'yesterday':
      const y = new Date(now); y.setDate(y.getDate() - 1);
      filters.value.startDate = fmt(y);
      filters.value.endDate = fmt(y);
      break;
    case 'last7days':
      const d7 = new Date(now); d7.setDate(d7.getDate() - 7);
      filters.value.startDate = fmt(d7);
      filters.value.endDate = fmt(now);
      break;
    case 'last30days':
      const d30 = new Date(now); d30.setDate(d30.getDate() - 30);
      filters.value.startDate = fmt(d30);
      filters.value.endDate = fmt(now);
      break;
    case 'thisMonth':
      filters.value.startDate = fmt(new Date(now.getFullYear(), now.getMonth(), 1));
      filters.value.endDate = fmt(now);
      break;
    case 'lastMonth':
      const lm = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const lme = new Date(now.getFullYear(), now.getMonth(), 0);
      filters.value.startDate = fmt(lm);
      filters.value.endDate = fmt(lme);
      break;
  }
  applyFilters();
}

function applyFilters() {
  currentPage.value = 1;
  loadTransactions();
}

function debounceSearch() {
  if (searchTimeout) clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => applyFilters(), 400);
}

function resetFilters() {
  filters.value = { startDate: '', endDate: '', paymentMethod: '', status: '', keyword: '' };
  currentPage.value = 1;
  loadTransactions();
}

function sortBy(field) {
  if (sortField.value === field) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortField.value = field;
    sortDir.value = 'asc';
  }
}

function toggleExpand(id) {
  expandedTxnId.value = expandedTxnId.value === id ? null : id;
}

function goToPage(page) {
  if (page < 1 || page > totalPages.value) return;
  currentPage.value = page;
}

async function loadTransactions() {
  loading.value = true;
  errorMessage.value = '';
  try {
    const params = new URLSearchParams();
    if (filters.value.startDate) params.append('start_date', filters.value.startDate);
    if (filters.value.endDate) params.append('end_date', filters.value.endDate);
    if (filters.value.paymentMethod) params.append('payment_method', filters.value.paymentMethod);
    if (filters.value.status) params.append('status', filters.value.status);
    if (filters.value.keyword) params.append('search', filters.value.keyword);
    params.append('page', currentPage.value);
    params.append('limit', pageSize.value);

    const res = await apiClient.get(`/pos/transactions?${params.toString()}`);
    const data = res.data;
    transactions.value = data.transactions || data || [];
  } catch (err) {
    errorMessage.value = err.message;
  } finally {
    loading.value = false;
  }
}

function viewDetails(txn) {
  selectedTransaction.value = txn;
  showDetailModal.value = true;
}

async function refundTransaction(txn) {
  if (!confirm(`確定要退款交易 ${txn.id}？金額 $${txn.total?.toLocaleString()}`)) return;
  try {
    await apiClient.post(`/pos/transactions/${txn.id}/refund`);
    await loadTransactions();
    alert('退款成功');
  } catch (err) {
    alert(err.message);
  }
}

function exportCSV() {
  const headers = ['交易編號', '時間', '客戶', '小計', '稅金', '合計', '付款方式', '找零', '狀態'];
  const rows = sortedTransactions.value.map(t => [
    t.id, formatDateTime(t.created_at), t.customer_name || '一般客戶',
    t.subtotal, t.tax, t.total, t.payment_method, t.change, t.status
  ]);
  const csv = [headers, ...rows].map(r => r.join(',')).join('\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `pos_transactions_${new Date().toISOString().split('T')[0]}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

function formatDateTime(dt) {
  if (!dt) return '-';
  return new Date(dt).toLocaleString('zh-TW');
}

function paymentMethodLabel(m) {
  return { cash: '現金', credit: '信用卡', linepay: 'LINE Pay' }[m] || m;
}

function statusLabel(s) {
  return { completed: '已完成', pending: '處理中', refunded: '已退款', cancelled: '已取消' }[s] || s;
}

function statusColor(s) {
  return { completed: 'success', pending: 'warning', refunded: 'danger', cancelled: 'muted' }[s] || 'muted';
}

onMounted(() => {
  const now = new Date();
  const fmt = d => d.toISOString().split('T')[0];
  filters.value.startDate = fmt(new Date(now.getFullYear(), now.getMonth(), 1));
  filters.value.endDate = fmt(now);
  loadTransactions();
});
</script>

<style scoped>
.filter-section { margin-bottom: 1.5rem; }
.filter-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 1rem; margin-bottom: 1rem; }
.filter-group { display: flex; flex-direction: column; gap: 0.35rem; }
.filter-group label { font-size: 0.85rem; color: var(--text-muted); }
.quick-date-btns { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.btn-sm { padding: 0.35rem 0.75rem; font-size: 0.85rem; }
.stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
.table-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
.table-actions { display: flex; gap: 0.5rem; }
.sortable { cursor: pointer; user-select: none; }
.sortable:hover { color: var(--color-primary); }
.txid { font-family: monospace; font-size: 0.85rem; }
.amount { font-weight: 600; color: var(--color-primary); }
.payment-badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.payment-badge.cash { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.payment-badge.credit { background: rgba(99, 102, 241, 0.15); color: #6366f1; }
.payment-badge.linepay { background: rgba(34, 197, 94, 0.15); color: #22c55e; }
.sku-tag { font-family: monospace; font-size: 0.75rem; padding: 0.15rem 0.4rem; background: var(--bg-secondary); border-radius: 4px; }
.transaction-row { cursor: pointer; transition: background 0.2s; }
.transaction-row:hover { background: var(--bg-hover); }
.transaction-row.expanded { background: rgba(99, 102, 241, 0.08); }
.detail-row td { padding: 0 !important; }
.detail-content { padding: 1.5rem; background: var(--bg-secondary); border-bottom: 1px solid var(--border-color); }
.detail-content h4 { margin-bottom: 1rem; color: var(--color-primary); }
.detail-table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
.detail-table th, .detail-table td { text-align: left; padding: 0.5rem; border-bottom: 1px solid var(--border-color); }
.detail-table th { font-size: 0.85rem; color: var(--text-muted); }
.detail-summary { display: flex; flex-direction: column; gap: 0.35rem; font-size: 0.9rem; }
.detail-summary .total { font-weight: 700; font-size: 1.1rem; color: var(--color-primary); margin-top: 0.5rem; }
.loading-state { display: flex; flex-direction: column; align-items: center; padding: 3rem; color: var(--text-muted); }
.loading-state .spinner { animation: spin 1s linear infinite; margin-bottom: 1rem; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; padding: 3rem; color: var(--text-muted); }
.empty-state svg { opacity: 0.3; margin-bottom: 1rem; }
.pagination { display: flex; align-items: center; justify-content: center; gap: 0.75rem; margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid var(--border-color); }
.page-info { padding: 0.5rem 1rem; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-content { width: 90%; max-width: 700px; max-height: 85vh; overflow-y: auto; padding: 0; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); }
.modal-header h2 { margin: 0; font-size: 1.1rem; }
.modal-body { padding: 1.5rem; }
.detail-section { margin-bottom: 1.5rem; }
.detail-section:last-child { margin-bottom: 0; }
.detail-section h4 { margin-bottom: 0.75rem; color: var(--color-primary); font-size: 0.95rem; }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 0.75rem; }
.detail-item { display: flex; gap: 0.5rem; font-size: 0.9rem; }
.detail-item label { color: var(--text-muted); }
.summary-box { background: var(--bg-secondary); border-radius: 8px; padding: 1rem; }
.summary-row { display: flex; justify-content: space-between; padding: 0.4rem 0; }
.summary-row.total { font-size: 1.15rem; font-weight: 700; color: var(--color-primary); border-top: 2px solid var(--border-color); margin-top: 0.5rem; padding-top: 0.75rem; }
.alert { display: flex; align-items: center; gap: 0.75rem; padding: 1rem; border-radius: 8px; margin-bottom: 1rem; }
.alert-error { background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; color: #ef4444; }
.badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.badge-success { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.badge-warning { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
.badge-danger { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.badge-muted { background: var(--bg-secondary); color: var(--text-muted); }
.text-muted { color: var(--text-muted); }
.text-sm { font-size: 0.85rem; }
</style>