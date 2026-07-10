<template>
  <div class="animate-fade-in">
    <h1>退貨管理</h1>
    <p class="subtitle">處理銷貨退貨與託售退貨，可完成或取消退貨單</p>

    <div class="grid-cols-2">
      <!-- Left: Return List -->
      <div class="glass-card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 1rem;">
          <h2>退貨單列表</h2>
          <button class="btn-primary" @click="fetchReturns" :disabled="loading">
            {{ loading ? '載入中...' : '重新整理' }}
          </button>
        </div>

        <!-- Filter -->
        <div class="form-group" style="margin-bottom: 1rem;">
          <label>狀態篩選</label>
          <select v-model="statusFilter" @change="fetchReturns">
            <option value="">全部</option>
            <option value="PENDING">待處理</option>
            <option value="COMPLETED">已完成</option>
            <option value="CANCELLED">已取消</option>
          </select>
        </div>

        <!-- Loading -->
        <div v-if="loading" style="text-align:center; padding: 2rem; color: var(--text-muted);">
          載入中...
        </div>

        <!-- Empty -->
        <div v-else-if="returns.length === 0" style="text-align:center; padding: 2rem; color: var(--text-muted);">
          尚無退貨單
        </div>

        <!-- Return List -->
        <div v-else class="return-list">
          <div
            v-for="ret in returns"
            :key="ret.id"
            class="return-item"
            :class="{ active: selectedReturn && selectedReturn.id === ret.id }"
            @click="selectReturn(ret)"
          >
            <div class="return-header">
              <span class="return-no">{{ ret.return_no }}</span>
              <span class="return-status" :class="'status-' + ret.status.toLowerCase()">
                {{ statusLabel(ret.status) }}
              </span>
            </div>
            <div class="return-reason">{{ ret.reason || '未填寫原因' }}</div>
            <div class="return-meta">
              <span>{{ formatDate(ret.created_at) }}</span>
              <span v-if="ret.original_order_no">原始單號：{{ ret.original_order_no }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Return Detail -->
      <div class="glass-card">
        <h2>退貨單詳情</h2>

        <div v-if="!selectedReturn" style="text-align:center; padding: 3rem; color: var(--text-muted);">
          請選擇左側退貨單以查看詳情
        </div>

        <div v-else class="return-detail animate-fade-in">
          <!-- Header Info -->
          <div class="detail-section">
            <div class="detail-row">
              <span class="detail-label">退貨單號</span>
              <span class="detail-value">{{ selectedReturn.return_no }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">狀態</span>
              <span class="detail-value">
                <span class="return-status" :class="'status-' + selectedReturn.status.toLowerCase()">
                  {{ statusLabel(selectedReturn.status) }}
                </span>
              </span>
            </div>
            <div class="detail-row">
              <span class="detail-label">退貨原因</span>
              <span class="detail-value">{{ selectedReturn.reason || '未填寫' }}</span>
            </div>
            <div class="detail-row" v-if="selectedReturn.original_order_no">
              <span class="detail-label">原始單號</span>
              <span class="detail-value">{{ selectedReturn.original_order_no }}</span>
            </div>
            <div class="detail-row" v-if="selectedReturn.notes">
              <span class="detail-label">備註</span>
              <span class="detail-value">{{ selectedReturn.notes }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">建立時間</span>
              <span class="detail-value">{{ formatDateTime(selectedReturn.created_at) }}</span>
            </div>
            <div class="detail-row" v-if="selectedReturn.completed_at">
              <span class="detail-label">完成時間</span>
              <span class="detail-value">{{ formatDateTime(selectedReturn.completed_at) }}</span>
            </div>
            <div class="detail-row" v-if="selectedReturn.cancelled_at">
              <span class="detail-label">取消時間</span>
              <span class="detail-value">{{ formatDateTime(selectedReturn.cancelled_at) }}</span>
            </div>
          </div>

          <!-- Return Items -->
          <div v-if="selectedReturn.items && selectedReturn.items.length > 0" class="detail-section">
            <h3>退貨商品</h3>
            <table class="detail-table">
              <thead>
                <tr>
                  <th>商品</th>
                  <th>數量</th>
                  <th>單位</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in selectedReturn.items" :key="item.id">
                  <td>{{ item.product_name || item.product_code || 'N/A' }}</td>
                  <td>{{ item.qty }}</td>
                  <td>{{ item.unit || '件' }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Actions -->
          <div class="detail-actions" v-if="selectedReturn.status === 'PENDING'">
            <button class="btn-success" @click="completeReturn" :disabled="actionLoading">
              {{ actionLoading ? '處理中...' : '完成退貨' }}
            </button>
            <button class="btn-danger" @click="cancelReturn" :disabled="actionLoading">
              {{ actionLoading ? '處理中...' : '取消退貨' }}
            </button>
          </div>

          <div v-else-if="selectedReturn.status === 'COMPLETED'" style="text-align:center; color: var(--success); padding: 1rem;">
            此退貨單已完成
          </div>

          <div v-else-if="selectedReturn.status === 'CANCELLED'" style="text-align:center; color: var(--text-muted); padding: 1rem;">
            此退貨單已取消
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const returns = ref([])
const selectedReturn = ref(null)
const loading = ref(false)
const actionLoading = ref(false)
const statusFilter = ref('')

async function fetchReturns() {
  loading.value = true
  try {
    let url = '/returns'
    if (statusFilter.value) {
      url += `?status=${statusFilter.value}`
    }
    const res = await apiClient.get(url)
    returns.value = Array.isArray(res.data) ? res.data : (res.data.data || [])
  } catch (e) {
    console.error('fetchReturns error:', e)
  } finally {
    loading.value = false
  }
}

async function selectReturn(ret) {
  selectedReturn.value = ret
  try {
    const res = await apiClient.get(`/returns/${ret.id}`)
    selectedReturn.value = res.data.data || res.data
  } catch (e) {
    console.error('fetchReturnDetail error:', e)
  }
}

async function completeReturn() {
  if (!selectedReturn.value) return
  if (!confirm(`確定要完成退貨單 ${selectedReturn.value.return_no}？`)) return
  actionLoading.value = true
  try {
    await apiClient.post(`/returns/${selectedReturn.value.id}/complete`)
    await fetchReturns()
    const updated = returns.value.find(r => r.id === selectedReturn.value.id)
    if (updated) selectedReturn.value = { ...updated }
  } catch (e) {
    console.error('completeReturn error:', e)
    alert('操作失敗：' + e.message)
  } finally {
    actionLoading.value = false
  }
}

async function cancelReturn() {
  if (!selectedReturn.value) return
  if (!confirm(`確定要取消退貨單 ${selectedReturn.value.return_no}？`)) return
  actionLoading.value = true
  try {
    await apiClient.post(`/returns/${selectedReturn.value.id}/cancel`)
    await fetchReturns()
    const updated = returns.value.find(r => r.id === selectedReturn.value.id)
    if (updated) selectedReturn.value = { ...updated }
  } catch (e) {
    console.error('cancelReturn error:', e)
    alert('操作失敗：' + e.message)
  } finally {
    actionLoading.value = false
  }
}

function statusLabel(status) {
  const map = { PENDING: '待處理', COMPLETED: '已完成', CANCELLED: '已取消' }
  return map[status] || status
}

function formatDate(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleDateString('zh-TW')
}

function formatDateTime(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleString('zh-TW')
}

onMounted(() => {
  fetchReturns()
})
</script>

<style scoped>
.return-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 65vh;
  overflow-y: auto;
}

.return-item {
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-card);
  padding: 0.75rem 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.return-item:hover {
  background: rgba(255, 255, 255, 0.05);
  border-color: var(--accent);
}

.return-item.active {
  background: rgba(99, 102, 241, 0.1);
  border-color: var(--accent);
}

.return-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.25rem;
}

.return-no {
  font-weight: 600;
  font-size: 0.9rem;
}

.return-status {
  font-size: 0.75rem;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  font-weight: 600;
}

.status-pending {
  background: rgba(234, 179, 8, 0.2);
  color: #eab308;
}

.status-completed {
  background: rgba(34, 197, 94, 0.2);
  color: #22c55e;
}

.status-cancelled {
  background: rgba(239, 68, 68, 0.2);
  color: #ef4444;
}

.return-reason {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}

.return-meta {
  display: flex;
  gap: 1rem;
  font-size: 0.75rem;
  color: var(--text-secondary);
}

.return-detail {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.detail-section {
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-card);
  padding: 1rem;
}

.detail-section h3 {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin-bottom: 0.75rem;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.4rem 0;
  border-bottom: 1px solid var(--border-glass);
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-label {
  color: var(--text-muted);
  font-size: 0.85rem;
}

.detail-value {
  font-weight: 500;
}

.detail-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.85rem;
}

.detail-table th {
  text-align: left;
  color: var(--text-muted);
  padding: 0.4rem 0.5rem;
  border-bottom: 1px solid var(--border-glass);
}

.detail-table td {
  padding: 0.4rem 0.5rem;
  border-bottom: 1px solid var(--border-glass);
}

.detail-table tr:last-child td {
  border-bottom: none;
}

.detail-actions {
  display: flex;
  gap: 0.75rem;
  padding: 0.5rem 0;
}

.btn-success {
  background: rgba(34, 197, 94, 0.15);
  color: #22c55e;
  border: 1px solid rgba(34, 197, 94, 0.3);
  border-radius: var(--radius-btn);
  padding: 0.5rem 1.5rem;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-success:hover:not(:disabled) {
  background: rgba(34, 197, 94, 0.25);
}

.btn-success:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-danger {
  background: rgba(239, 68, 68, 0.15);
  color: #ef4444;
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: var(--radius-btn);
  padding: 0.5rem 1.5rem;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-danger:hover:not(:disabled) {
  background: rgba(239, 68, 68, 0.25);
}

.btn-danger:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: rgba(99, 102, 241, 0.15);
  color: var(--accent);
  border: 1px solid rgba(99, 102, 241, 0.3);
  border-radius: var(--radius-btn);
  padding: 0.4rem 1rem;
  cursor: pointer;
  font-size: 0.85rem;
  transition: all 0.2s;
}

.btn-primary:hover:not(:disabled) {
  background: rgba(99, 102, 241, 0.25);
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>