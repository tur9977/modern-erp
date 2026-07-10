<template>
  <div class="quotes-container">
    <div class="panel-header">
      <h2>報價管理</h2>
      <button class="btn-primary" @click="showNewQuoteForm = true">+ 新建報價</button>
    </div>

    <div class="quotes-layout">
      <!-- 左側：報價單列表 -->
      <div class="quotes-list-panel">
        <div class="filter-bar">
          <select v-model="filterStatus" class="filter-select">
            <option value="">全部狀態</option>
            <option value="PENDING">待處理</option>
            <option value="ACCEPTED">已接受</option>
            <option value="REJECTED">已拒絕</option>
            <option value="CONVERTED">已轉單</option>
          </select>
          <input v-model="searchKeyword" placeholder="搜尋客戶或單號..." class="search-input" />
        </div>

        <div v-if="loadingQuotes" class="loading">載入中...</div>
        <div v-else-if="filteredQuotes.length === 0" class="empty-state">尚無報價單</div>
        <div v-else class="quote-list">
          <div
            v-for="quote in filteredQuotes"
            :key="quote.id"
            :class="['quote-card', { active: selectedQuote?.id === quote.id }]"
            @click="selectQuote(quote)"
          >
            <div class="quote-card-header">
              <span class="quote-id">{{ quote.quote_number || quote.id }}</span>
              <span :class="['status-badge', quote.status?.toLowerCase()]">{{ statusLabel(quote.status) }}</span>
            </div>
            <div class="quote-card-body">
              <div class="quote-customer">{{ quote.customer_name || '未指定客戶' }}</div>
              <div class="quote-date">{{ formatDate(quote.created_at) }}</div>
            </div>
            <div class="quote-card-footer">
              <span class="quote-amount">{{ formatCurrency(quote.total_amount) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 右側：選中報價單詳情 -->
      <div class="quote-detail-panel">
        <div v-if="!selectedQuote" class="empty-detail">
          <p>請選擇一份報價單</p>
        </div>
        <div v-else class="detail-content">
          <div class="detail-header">
            <div class="detail-title">
              <h3>報價單 {{ selectedQuote.quote_number || selectedQuote.id }}</h3>
              <span :class="['status-badge', selectedQuote.status?.toLowerCase()]">{{ statusLabel(selectedQuote.status) }}</span>
            </div>
            <div class="detail-actions">
              <button
                v-if="selectedQuote.status === 'PENDING'"
                class="btn-action btn-accept"
                @click="acceptQuote(selectedQuote.id)"
              >接受報價</button>
              <button
                v-if="selectedQuote.status === 'PENDING'"
                class="btn-action btn-reject"
                @click="rejectQuote(selectedQuote.id)"
              >拒絕報價</button>
              <button
                v-if="selectedQuote.status === 'ACCEPTED'"
                class="btn-action btn-convert"
                @click="convertToOrder(selectedQuote.id)"
              >轉為正式訂單</button>
            </div>
          </div>

          <div class="detail-info">
            <div class="info-row">
              <span class="info-label">客戶：</span>
              <span class="info-value">{{ selectedQuote.customer_name || '未指定' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">日期：</span>
              <span class="info-value">{{ formatDate(selectedQuote.created_at) }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">有效期：</span>
              <span class="info-value">{{ formatDate(selectedQuote.valid_until) }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">備註：</span>
              <span class="info-value">{{ selectedQuote.notes || '-' }}</span>
            </div>
          </div>

          <!-- 商品明細 -->
          <div class="line-items-section">
            <h4>商品明細</h4>
            <table class="items-table">
              <thead>
                <tr>
                  <th>商品</th>
                  <th>數量</th>
                  <th>單價</th>
                  <th>小計</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in selectedQuote.items" :key="item.id">
                  <td>{{ item.product_name || item.name || '未命名' }}</td>
                  <td>{{ item.quantity }}</td>
                  <td>{{ formatCurrency(item.unit_price) }}</td>
                  <td>{{ formatCurrency(item.subtotal) }}</td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <td colspan="3" class="text-right"><strong>總計：</strong></td>
                  <td><strong>{{ formatCurrency(selectedQuote.total_amount) }}</strong></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- 新建報價表單 -->
    <div v-if="showNewQuoteForm" class="modal-overlay" @click.self="showNewQuoteForm = false">
      <div class="modal-content">
        <div class="modal-header">
          <h3>新建報價</h3>
          <button class="btn-close" @click="showNewQuoteForm = false">×</button>
        </div>
        <form @submit.prevent="createQuote" class="quote-form">
          <div class="form-group">
            <label>客戶</label>
            <select v-model="newQuote.customer_id" required>
              <option value="">選擇客戶</option>
              <option v-for="c in customers" :key="c.id" :value="c.id">{{ c.name }}</option>
            </select>
          </div>
          <div class="form-group">
            <label>有效期至</label>
            <input type="date" v-model="newQuote.valid_until" required />
          </div>
          <div class="form-group">
            <label>備註</label>
            <textarea v-model="newQuote.notes" rows="3"></textarea>
          </div>
          <div class="form-actions">
            <button type="button" class="btn-secondary" @click="showNewQuoteForm = false">取消</button>
            <button type="submit" class="btn-primary">建立報價</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const loadingQuotes = ref(false)
const quotes = ref([])
const selectedQuote = ref(null)
const showNewQuoteForm = ref(false)
const filterStatus = ref('')
const searchKeyword = ref('')
const customers = ref([])

const newQuote = ref({
  customer_id: '',
  valid_until: '',
  notes: ''
})

const filteredQuotes = computed(() => {
  let result = quotes.value
  if (filterStatus.value) {
    result = result.filter(q => q.status === filterStatus.value)
  }
  if (searchKeyword.value) {
    const kw = searchKeyword.value.toLowerCase()
    result = result.filter(q =>
      (q.quote_number || '').toLowerCase().includes(kw) ||
      (q.customer_name || '').toLowerCase().includes(kw)
    )
  }
  return result
})

async function fetchQuotes() {
  loadingQuotes.value = true
  try {
    const res = await apiClient.get('/quotes/')
    quotes.value = res.data
  } catch (e) {
    console.error('fetchQuotes error:', e)
  } finally {
    loadingQuotes.value = false
  }
}

async function fetchCustomers() {
  try {
    const res = await apiClient.get('/customers/')
    customers.value = res.data
  } catch (e) {
    console.error('fetchCustomers error:', e)
  }
}

async function selectQuote(quote) {
  try {
    const res = await apiClient.get(`/quotes/${quote.id}`)
    selectedQuote.value = res.data
  } catch (e) {
    console.error('selectQuote error:', e)
    selectedQuote.value = quote
  }
}

async function createQuote() {
  try {
    const res = await apiClient.post('/quotes/', newQuote.value)
    if (res.status === 200 || res.status === 201) {
      showNewQuoteForm.value = false
      newQuote.value = { customer_id: '', valid_until: '', notes: '' }
      await fetchQuotes()
    }
  } catch (e) {
    console.error('createQuote error:', e)
  }
}

async function acceptQuote(id) {
  try {
    await apiClient.post(`/quotes/${id}/accept`)
    await fetchQuotes()
    if (selectedQuote.value?.id === id) {
      await selectQuote({ id })
    }
  } catch (e) {
    console.error('acceptQuote error:', e)
  }
}

async function rejectQuote(id) {
  try {
    await apiClient.post(`/quotes/${id}/reject`)
    await fetchQuotes()
    if (selectedQuote.value?.id === id) {
      await selectQuote({ id })
    }
  } catch (e) {
    console.error('rejectQuote error:', e)
  }
}

async function convertToOrder(id) {
  try {
    await apiClient.post(`/quotes/${id}/convert`)
    alert('已成功轉為正式訂單！')
    await fetchQuotes()
  } catch (e) {
    console.error('convertToOrder error:', e)
  }
}

function statusLabel(status) {
  const map = { PENDING: '待處理', ACCEPTED: '已接受', REJECTED: '已拒絕', CONVERTED: '已轉單' }
  return map[status] || status || '-'
}

function formatDate(date) {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('zh-TW')
}

function formatCurrency(amount) {
  if (amount == null) return '-'
  return new Intl.NumberFormat('zh-TW', { style: 'currency', currency: 'TWD' }).format(amount)
}

onMounted(() => {
  fetchQuotes()
  fetchCustomers()
})
</script>

<style scoped>
.quotes-container {
  padding: 1.5rem;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.panel-header h2 {
  margin: 0;
  font-size: 1.5rem;
  color: #333;
}

.quotes-layout {
  display: grid;
  grid-template-columns: 380px 1fr;
  gap: 1.5rem;
  flex: 1;
  min-height: 0;
}

.quotes-list-panel {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 1rem;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.filter-bar {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.filter-select, .search-input {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 0.9rem;
}

.filter-select { width: 120px; }
.search-input { flex: 1; }

.quote-list {
  flex: 1;
  overflow-y: auto;
}

.quote-card {
  padding: 0.75rem;
  border: 1px solid #eee;
  border-radius: 8px;
  margin-bottom: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
}

.quote-card:hover { background: #f8f9fa; }
.quote-card.active { border-color: #4a90d9; background: #f0f7ff; }

.quote-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.quote-id {
  font-weight: 600;
  color: #333;
  font-size: 0.9rem;
}

.quote-card-body { margin-bottom: 0.5rem; }
.quote-customer { font-weight: 500; color: #555; }
.quote-date { font-size: 0.8rem; color: #888; }

.quote-card-footer {
  display: flex;
  justify-content: flex-end;
}

.quote-amount {
  font-weight: 600;
  color: #2d5a8a;
}

.status-badge {
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
}

.status-badge.pending { background: #fff3cd; color: #856404; }
.status-badge.accepted { background: #d4edda; color: #155724; }
.status-badge.rejected { background: #f8d7da; color: #721c24; }
.status-badge.converted { background: #d1ecf1; color: #0c5460; }

.quote-detail-panel {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
}

.empty-detail {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #888;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #eee;
}

.detail-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.detail-title h3 { margin: 0; }

.detail-actions {
  display: flex;
  gap: 0.5rem;
}

.detail-info {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.info-row { display: flex; gap: 0.5rem; }
.info-label { color: #888; font-size: 0.9rem; }
.info-value { color: #333; font-size: 0.9rem; }

.line-items-section h4 { margin: 0 0 1rem 0; }

.items-table {
  width: 100%;
  border-collapse: collapse;
}

.items-table th, .items-table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid #eee;
}

.items-table th {
  background: #f8f9fa;
  font-weight: 600;
  color: #555;
  font-size: 0.85rem;
}

.items-table tfoot td { border-top: 2px solid #ddd; }

.text-right { text-align: right; }

.btn-primary {
  background: #4a90d9;
  color: #fff;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
}

.btn-primary:hover { background: #3a7bc8; }

.btn-action {
  padding: 0.4rem 0.8rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
  margin-left: 0.5rem;
}

.btn-accept { background: #28a745; color: #fff; }
.btn-reject { background: #dc3545; color: #fff; }
.btn-convert { background: #17a2b8; color: #fff; }

.btn-secondary {
  background: #e9ecef;
  color: #333;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #888;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #fff;
  border-radius: 12px;
  padding: 1.5rem;
  width: 480px;
  max-width: 90%;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.modal-header h3 { margin: 0; }

.quote-form .form-group {
  margin-bottom: 1rem;
}

.quote-form label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #555;
}

.quote-form input,
.quote-form select,
.quote-form textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 6px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
  margin-top: 1rem;
}

.loading, .empty-state {
  padding: 2rem;
  text-align: center;
  color: #888;
}
</style>