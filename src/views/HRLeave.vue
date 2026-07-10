<template>
  <div class="animate-fade-in">
    <h1>請假申請</h1>
    <p class="subtitle">DOUBLE ERP 員工請假申請與歷史查詢</p>

    <!-- Error/Success Messages -->
    <div v-if="errorMessage" class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
      {{ errorMessage }}
    </div>
    <div v-if="successMessage" class="alert alert-success">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      {{ successMessage }}
    </div>

    <div class="grid-cols-2">
      <!-- Left: Leave Balance -->
      <div class="glass-card">
        <h2 style="display: flex; align-items: center; gap: 0.5rem;">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          假別與剩餘時數
        </h2>
        <div class="balance-grid">
          <div class="balance-card" v-for="balance in leaveBalances" :key="balance.type" :class="balance.type">
            <div class="balance-icon">
              <svg v-if="balance.type === 'annual'" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
              <svg v-else-if="balance.type === 'sick'" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            </div>
            <div class="balance-info">
              <span class="balance-type">{{ leaveTypeLabel(balance.type) }}</span>
              <span class="balance-hours">{{ balance.hours }}</span>
              <span class="balance-unit">小時</span>
            </div>
            <div class="balance-bar">
              <div class="balance-fill" :style="{ width: balance.usedPercent + '%' }"></div>
            </div>
            <span class="balance-used">已使用 {{ balance.used }} 小時</span>
          </div>
        </div>
      </div>

      <!-- Right: Quick Stats -->
      <div class="glass-card">
        <h2 style="display: flex; align-items: center; gap: 0.5rem;">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
          本月請假概況
        </h2>
        <div class="stats-list">
          <div class="stat-row">
            <span class="stat-label">本月已申請</span>
            <span class="stat-value">{{ monthStats.total }} 次</span>
          </div>
          <div class="stat-row">
            <span class="stat-label">待審核</span>
            <span class="stat-value pending">{{ monthStats.pending }} 次</span>
          </div>
          <div class="stat-row">
            <span class="stat-label">已完成</span>
            <span class="stat-value approved">{{ monthStats.approved }} 次</span>
          </div>
          <div class="stat-row">
            <span class="stat-label">已駁回</span>
            <span class="stat-value rejected">{{ monthStats.rejected }} 次</span>
          </div>
          <div class="stat-row total">
            <span class="stat-label">共計時數</span>
            <span class="stat-value">{{ monthStats.totalHours }} 小時</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Leave Application Form -->
    <div class="glass-card form-section">
      <h2 style="display: flex; align-items: center; gap: 0.5rem;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        新增請假申請
      </h2>
      <form @submit.prevent="submitLeave" class="leave-form">
        <div class="form-row">
          <div class="form-group">
            <label>員工</label>
            <select v-model="form.employee_id" required>
              <option value="">-- 選擇員工 --</option>
              <option v-for="emp in employees" :key="emp.id" :value="emp.id">{{ emp.name }} ({{ emp.employee_no }})</option>
            </select>
          </div>
          <div class="form-group">
            <label>假別 <span class="required">*</span></label>
            <select v-model="form.type" required>
              <option value="annual">特休假</option>
              <option value="sick">病假</option>
              <option value="personal">事假</option>
              <option value="unpaid">無薪假</option>
              <option value="marriage">婚假</option>
              <option value="funeral">喪假</option>
              <option value="other">其他</option>
            </select>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>起始日期 <span class="required">*</span></label>
            <input type="date" v-model="form.start_date" required />
          </div>
          <div class="form-group">
            <label>結束日期 <span class="required">*</span></label>
            <input type="date" v-model="form.end_date" required />
          </div>
          <div class="form-group">
            <label>請假時數 <span class="required">*</span></label>
            <input type="number" v-model.number="form.hours" min="1" max="24" step="0.5" required />
          </div>
        </div>
        <div class="form-group full">
          <label>請假原因 <span class="required">*</span></label>
          <textarea v-model="form.reason" rows="3" placeholder="請詳細說明請假原因..." required></textarea>
        </div>
        <div class="form-group full">
          <label>上傳附件（可选）</label>
          <div class="file-upload" @dragover.prevent="dragOver = true" @dragleave="dragOver = false" @drop.prevent="handleFileDrop" :class="{ 'drag-over': dragOver }">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
            <p>拖放檔案到此處，或 <label class="file-link">點擊上傳<input type="file" @change="handleFileSelect" accept=".pdf,.jpg,.png,.doc,.docx" hidden /></label></p>
            <p class="file-hint">支援 PDF, JPG, PNG, DOC, DOCX（最大 5MB）</p>
          </div>
          <div v-if="form.attachments.length > 0" class="file-list">
            <div v-for="(file, idx) in form.attachments" :key="idx" class="file-item">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/></svg>
              <span>{{ file.name }}</span>
              <button type="button" class="btn-icon btn-danger" @click="removeAttachment(idx)">×</button>
            </div>
          </div>
        </div>
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" @click="resetForm">清除表單</button>
          <button type="submit" class="btn btn-primary" :disabled="submitting">
            <span v-if="submitting">
              <svg class="spinner" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
              送出中...
            </span>
            <span v-else>送出申請</span>
          </button>
        </div>
      </form>
    </div>

    <!-- Leave History Table -->
    <div class="glass-card">
      <div class="table-header">
        <h2>請假歷史記錄</h2>
        <div class="table-controls">
          <select v-model="filterStatus" @change="loadLeaveHistory" style="padding: 0.5rem; border-radius: 6px; border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text);">
            <option value="">全部狀態</option>
            <option value="pending">待審核</option>
            <option value="approved">已核准</option>
            <option value="rejected">已駁回</option>
            <option value="cancelled">已取消</option>
          </select>
          <input type="month" v-model="filterMonth" @change="loadLeaveHistory" style="padding: 0.5rem; border-radius: 6px; border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text);" />
          <button class="btn btn-secondary" @click="loadLeaveHistory" :disabled="loadingHistory">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            重新整理
          </button>
        </div>
      </div>

      <div v-if="loadingHistory" class="loading-state">
        <svg class="spinner" xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
        <p>載入中...</p>
      </div>

      <table v-else>
        <thead>
          <tr>
            <th>申請日期</th>
            <th>員工</th>
            <th>假別</th>
            <th>期間</th>
            <th>時數</th>
            <th>原因</th>
            <th>狀態</th>
            <th>審核回覆</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="leave in leaveHistory" :key="leave.id">
            <tr class="leave-row" :class="{ expanded: expandedLeaveId === leave.id }" @click="toggleExpand(leave.id)">
              <td>{{ formatDate(leave.created_at) }}</td>
              <td>{{ leave.employee_name }}</td>
              <td><span :class="'leave-type-badge ' + leave.type">{{ leaveTypeLabel(leave.type) }}</span></td>
              <td>
                <div class="date-range">{{ formatDate(leave.start_date) }}</div>
                <div class="date-range-sub">至 {{ formatDate(leave.end_date) }}</div>
              </td>
              <td class="hours-cell">{{ leave.hours }}h</td>
              <td class="reason-cell">{{ leave.reason?.substring(0, 30) }}{{ leave.reason?.length > 30 ? '...' : '' }}</td>
              <td>
                <span :class="'badge badge-' + statusColor(leave.status)">{{ statusLabel(leave.status) }}</span>
              </td>
              <td class="reply-cell">{{ leave.reply || '-' }}</td>
              <td @click.stop>
                <button v-if="leave.status === 'pending'" class="btn-icon btn-warning" title="取消申請" @click="cancelLeave(leave)">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                </button>
                <button class="btn-icon" title="查看詳情" @click="viewLeaveDetail(leave)">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                </button>
              </td>
            </tr>
            <!-- Expanded Detail Row -->
            <tr v-if="expandedLeaveId === leave.id" class="detail-row">
              <td colspan="9">
                <div class="detail-content">
                  <h4>請假申請詳情 - {{ leave.id }}</h4>
                  <div class="detail-grid">
                    <div class="detail-item"><label>申請人</label><span>{{ leave.employee_name }} ({{ leave.employee_no }})</span></div>
                    <div class="detail-item"><label>假別</label><span>{{ leaveTypeLabel(leave.type) }}</span></div>
                    <div class="detail-item"><label>申請日期</label><span>{{ formatDate(leave.created_at) }}</span></div>
                    <div class="detail-item"><label>期間</label><span>{{ formatDate(leave.start_date) }} 至 {{ formatDate(leave.end_date) }}</span></div>
                    <div class="detail-item"><label>請假時數</label><span>{{ leave.hours }} 小時</span></div>
                    <div class="detail-item"><label>審核狀態</label><span :class="'badge badge-' + statusColor(leave.status)">{{ statusLabel(leave.status) }}</span></div>
                    <div class="detail-item full"><label>請假原因</label><span>{{ leave.reason }}</span></div>
                    <div class="detail-item full" v-if="leave.reply"><label>審核回覆</label><span>{{ leave.reply }}</span></div>
                    <div class="detail-item" v-if="leave.reviewer"><label>審核人</label><span>{{ leave.reviewer }}</span></div>
                    <div class="detail-item" v-if="leave.reviewed_at"><label>審核時間</label><span>{{ formatDateTime(leave.reviewed_at) }}</span></div>
                  </div>
                </div>
              </td>
            </tr>
          </template>
          <tr v-if="leaveHistory.length === 0 && !loadingHistory">
            <td colspan="9" class="empty-row">
              <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                <p>目前沒有請假記錄</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Leave Detail Modal -->
    <div v-if="showDetailModal" class="modal-overlay" @click.self="showDetailModal = false">
      <div class="modal-content glass-card">
        <div class="modal-header">
          <h2>請假詳情 - {{ selectedLeave?.id }}</h2>
          <button class="btn-icon" @click="showDetailModal = false">×</button>
        </div>
        <div class="modal-body" v-if="selectedLeave">
          <div class="detail-grid">
            <div class="detail-item"><label>申請人</label><span>{{ selectedLeave.employee_name }}</span></div>
            <div class="detail-item"><label>員工編號</label><span>{{ selectedLeave.employee_no }}</span></div>
            <div class="detail-item"><label>假別</label><span>{{ leaveTypeLabel(selectedLeave.type) }}</span></div>
            <div class="detail-item"><label>時數</label><span>{{ selectedLeave.hours }} 小時</span></div>
            <div class="detail-item"><label>起始日期</label><span>{{ formatDate(selectedLeave.start_date) }}</span></div>
            <div class="detail-item"><label>結束日期</label><span>{{ formatDate(selectedLeave.end_date) }}</span></div>
            <div class="detail-item"><label>申請日期</label><span>{{ formatDateTime(selectedLeave.created_at) }}</span></div>
            <div class="detail-item"><label>狀態</label><span :class="'badge badge-' + statusColor(selectedLeave.status)">{{ statusLabel(selectedLeave.status) }}</span></div>
            <div class="detail-item full"><label>原因</label><span>{{ selectedLeave.reason }}</span></div>
            <div class="detail-item full" v-if="selectedLeave.reply"><label>審核回覆</label><span>{{ selectedLeave.reply }}</span></div>
            <div class="detail-item" v-if="selectedLeave.reviewer"><label>審核人</label><span>{{ selectedLeave.reviewer }}</span></div>
            <div class="detail-item" v-if="selectedLeave.reviewed_at"><label>審核時間</label><span>{{ formatDateTime(selectedLeave.reviewed_at) }}</span></div>
          </div>
          <!-- Approval Actions for Pending -->
          <div v-if="selectedLeave.status === 'pending' && isManager" class="approval-actions">
            <h4>審核操作</h4>
            <div class="form-group">
              <label>審核意見</label>
              <textarea v-model="approvalReply" rows="2" placeholder="輸入審核意見（選填）..."></textarea>
            </div>
            <div style="display: flex; gap: 0.75rem; justify-content: flex-end;">
              <button class="btn btn-danger" @click="approveLeave(false)">駁回</button>
              <button class="btn btn-primary" @click="approveLeave(true)">核准</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

// Employees
const employees = ref([]);
const isManager = ref(false);

// Leave balances
const leaveBalances = ref([
  { type: 'annual', hours: 56, used: 8, usedPercent: 14 },
  { type: 'sick', hours: 42, used: 0, usedPercent: 0 },
  { type: 'personal', hours: 16, used: 4, usedPercent: 25 }
]);

// Month stats
const monthStats = ref({ total: 0, pending: 0, approved: 0, rejected: 0, totalHours: 0 });

// Leave history
const leaveHistory = ref([]);
const loadingHistory = ref(false);
const expandedLeaveId = ref(null);
const filterStatus = ref('');
const filterMonth = ref('');

// Form
const form = ref({ employee_id: '', type: 'annual', start_date: '', end_date: '', hours: 8, reason: '', attachments: [] });
const submitting = ref(false);
const dragOver = ref(false);

// Detail modal
const showDetailModal = ref(false);
const selectedLeave = ref(null);
const approvalReply = ref('');

// UI messages
const errorMessage = ref('');
const successMessage = ref('');

// Methods
function leaveTypeLabel(type) {
  const labels = {
    annual: '特休假', sick: '病假', personal: '事假',
    unpaid: '無薪假', marriage: '婚假', funeral: '喪假', other: '其他'
  };
  return labels[type] || type;
}

function statusLabel(s) {
  return { pending: '待審核', approved: '已核准', rejected: '已駁回', cancelled: '已取消' }[s] || s;
}

function statusColor(s) {
  return { pending: 'warning', approved: 'success', rejected: 'danger', cancelled: 'muted' }[s] || 'muted';
}

function formatDate(dt) {
  if (!dt) return '-';
  return new Date(dt).toLocaleDateString('zh-TW');
}

function formatDateTime(dt) {
  if (!dt) return '-';
  return new Date(dt).toLocaleString('zh-TW');
}

function toggleExpand(id) {
  expandedLeaveId.value = expandedLeaveId.value === id ? null : id;
}

async function loadLeaveHistory() {
  loadingHistory.value = true;
  try {
    const params = new URLSearchParams();
    if (filterStatus.value) params.append('status', filterStatus.value);
    if (filterMonth.value) params.append('month', filterMonth.value);

    const res = await apiClient.get(`/hr/leave?${params.toString()}`);
    leaveHistory.value = res.data.leaves || res.data || [];
  } catch (err) {
    errorMessage.value = err.message;
  } finally {
    loadingHistory.value = false;
  }
}

async function loadEmployees() {
  try {
    const res = await apiClient.get('/hr/employees');
    employees.value = res.data.employees || res.data || [];
  } catch (err) {
    console.error('載入員工失敗:', err);
  }
}

async function loadLeaveBalances() {
  try {
    const res = await apiClient.get('/hr/leave/balances');
    leaveBalances.value = res.data.balances || res.data || [];
  } catch (err) {
    console.error('載入假別餘額失敗:', err);
  }
}

async function loadMonthStats() {
  try {
    const res = await apiClient.get('/hr/leave/stats');
    monthStats.value = res.data;
  } catch (err) {
    console.error('載入統計失敗:', err);
  }
}

async function submitLeave() {
  if (!form.value.employee_id || !form.value.start_date || !form.value.end_date || !form.value.reason) {
    alert('請填寫所有必填欄位');
    return;
  }
  errorMessage.value = '';
  successMessage.value = '';
  submitting.value = true;
  try {
    const res = await apiClient.post('/hr/leave', form.value);
    const result = res.data;
    successMessage.value = `請假申請已送出，申請編號：${result.id}`;
    resetForm();
    await loadLeaveHistory();
    await loadLeaveBalances();
    await loadMonthStats();
    setTimeout(() => { successMessage.value = ''; }, 5000);
  } catch (err) {
    errorMessage.value = err.response?.data?.message || err.message;
    setTimeout(() => { errorMessage.value = ''; }, 5000);
  } finally {
    submitting.value = false;
  }
}

function resetForm() {
  form.value = { employee_id: '', type: 'annual', start_date: '', end_date: '', hours: 8, reason: '', attachments: [] };
}

function handleFileSelect(event) {
  const files = Array.from(event.target.files);
  validateAndAddFiles(files);
}

function handleFileDrop(event) {
  dragOver.value = false;
  const files = Array.from(event.dataTransfer.files);
  validateAndAddFiles(files);
}

function validateAndAddFiles(files) {
  const maxSize = 5 * 1024 * 1024;
  const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
  for (const file of files) {
    if (file.size > maxSize) {
      alert(`檔案 ${file.name} 超過 5MB 限制`);
      continue;
    }
    if (!allowedTypes.includes(file.type)) {
      alert(`檔案 ${file.name} 格式不支援`);
      continue;
    }
    form.value.attachments.push(file);
  }
}

function removeAttachment(idx) {
  form.value.attachments.splice(idx, 1);
}

async function cancelLeave(leave) {
  if (!confirm(`確定要取消申請 ${leave.id}？`)) return;
  try {
    await apiClient.post(`/hr/leave/${leave.id}/cancel`);
    await loadLeaveHistory();
    await loadLeaveBalances();
    await loadMonthStats();
    alert('已取消申請');
  } catch (err) {
    alert(err.message);
  }
}

function viewLeaveDetail(leave) {
  selectedLeave.value = leave;
  approvalReply.value = '';
  showDetailModal.value = true;
}

async function approveLeave(approved) {
  if (!selectedLeave.value) return;
  try {
    await apiClient.post(`/hr/leave/${selectedLeave.value.id}/approve`, { approved, reply: approvalReply.value });
    showDetailModal.value = false;
    await loadLeaveHistory();
    await loadMonthStats();
    alert(approved ? '已核准' : '已駁回');
  } catch (err) {
    alert(err.message);
  }
}

// Lifecycle
onMounted(() => {
  const now = new Date();
  filterMonth.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  loadEmployees();
  loadLeaveHistory();
  loadLeaveBalances();
  loadMonthStats();
});
</script>

<style scoped>
.balance-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; }
.balance-card { padding: 1.25rem; border-radius: 12px; background: var(--bg-secondary); border: 1px solid var(--border-color); display: flex; flex-direction: column; gap: 0.5rem; }
.balance-icon { color: var(--color-primary); }
.balance-info { display: flex; align-items: baseline; gap: 0.5rem; }
.balance-type { font-size: 0.85rem; color: var(--text-muted); flex: 1; }
.balance-hours { font-size: 2rem; font-weight: 700; color: var(--text); }
.balance-unit { font-size: 0.85rem; color: var(--text-muted); }
.balance-bar { height: 6px; background: var(--bg-hover); border-radius: 3px; overflow: hidden; }
.balance-fill { height: 100%; background: var(--color-primary); border-radius: 3px; transition: width 0.3s; }
.balance-used { font-size: 0.8rem; color: var(--text-muted); }
.balance-card.annual .balance-fill { background: #6366f1; }
.balance-card.sick .balance-fill { background: #ef4444; }
.balance-card.personal .balance-fill { background: #f59e0b; }
.stats-list { display: flex; flex-direction: column; gap: 0.5rem; }
.stat-row { display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color); }
.stat-row:last-child { border-bottom: none; }
.stat-row.total { border-top: 2px solid var(--border-color); margin-top: 0.5rem; padding-top: 1rem; font-weight: 700; }
.stat-label { color: var(--text-muted); }
.stat-value { font-weight: 600; }
.stat-value.pending { color: #f59e0b; }
.stat-value.approved { color: #10b981; }
.stat-value.rejected { color: #ef4444; }
.form-section { margin: 1.5rem 0; }
.leave-form { display: flex; flex-direction: column; gap: 1rem; }
.form-row { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; }
.form-group { display: flex; flex-direction: column; gap: 0.35rem; }
.form-group.full { grid-column: 1 / -1; }
.form-group label { font-size: 0.9rem; color: var(--text-muted); }
.required { color: #ef4444; }
.form-group input, .form-group select, .form-group textarea { padding: 0.65rem; border: 1px solid var(--border-color); border-radius: 6px; background: var(--bg-secondary); color: var(--text); font-size: 0.95rem; }
.form-group textarea { resize: vertical; }
.form-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1rem; }
.file-upload { border: 2px dashed var(--border-color); border-radius: 12px; padding: 2rem; text-align: center; cursor: pointer; transition: all 0.2s; color: var(--text-muted); }
.file-upload:hover, .file-upload.drag-over { border-color: var(--color-primary); background: rgba(99, 102, 241, 0.05); }
.file-link { color: var(--color-primary); cursor: pointer; text-decoration: underline; }
.file-hint { font-size: 0.8rem; margin-top: 0.5rem; }
.file-list { display: flex; flex-direction: column; gap: 0.5rem; margin-top: 0.75rem; }
.file-item { display: flex; align-items: center; gap: 0.5rem; padding: 0.5rem; background: var(--bg-secondary); border-radius: 6px; }
.file-item span { flex: 1; font-size: 0.9rem; }
.table-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
.table-controls { display: flex; gap: 0.75rem; align-items: center; }
.leave-type-badge { display: inline-block; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.leave-type-badge.annual { background: rgba(99, 102, 241, 0.15); color: #6366f1; }
.leave-type-badge.sick { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.leave-type-badge.personal { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
.leave-type-badge.unpaid { background: var(--bg-secondary); color: var(--text-muted); }
.leave-type-badge.marriage { background: rgba(236, 72, 153, 0.15); color: #ec4899; }
.leave-type-badge.funeral { background: rgba(107, 114, 128, 0.15); color: #6b7280; }
.leave-type-badge.other { background: var(--bg-secondary); color: var(--text-muted); }
.date-range { font-size: 0.9rem; }
.date-range-sub { font-size: 0.8rem; color: var(--text-muted); }
.hours-cell { font-weight: 600; color: var(--color-primary); }
.reason-cell { font-size: 0.85rem; color: var(--text-muted); max-width: 200px; }
.reply-cell { font-size: 0.85rem; color: var(--text-muted); max-width: 150px; }
.leave-row { cursor: pointer; transition: background 0.2s; }
.leave-row:hover { background: var(--bg-hover); }
.leave-row.expanded { background: rgba(99, 102, 241, 0.08); }
.detail-row td { padding: 0 !important; }
.detail-content { padding: 1.5rem; background: var(--bg-secondary); border-bottom: 1px solid var(--border-color); }
.detail-content h4 { margin-bottom: 1rem; color: var(--color-primary); }
.detail-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 0.75rem; }
.detail-item { display: flex; flex-direction: column; gap: 0.25rem; font-size: 0.9rem; }
.detail-item.full { grid-column: 1 / -1; }
.detail-item label { color: var(--text-muted); font-size: 0.8rem; }
.loading-state { display: flex; flex-direction: column; align-items: center; padding: 3rem; color: var(--text-muted); }
.loading-state .spinner { animation: spin 1s linear infinite; margin-bottom: 1rem; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; padding: 3rem; color: var(--text-muted); }
.empty-state svg { opacity: 0.3; margin-bottom: 1rem; }
.empty-row td { padding: 2rem !important; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-content { width: 90%; max-width: 600px; max-height: 85vh; overflow-y: auto; padding: 0; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); }
.modal-header h2 { margin: 0; font-size: 1.1rem; }
.modal-body { padding: 1.5rem; }
.approval-actions { margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid var(--border-color); }
.approval-actions h4 { margin-bottom: 1rem; }
.alert { display: flex; align-items: center; gap: 0.75rem; padding: 1rem; border-radius: 8px; margin-bottom: 1rem; }
.alert-error { background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; color: #ef4444; }
.alert-success { background: rgba(16, 185, 129, 0.15); border: 1px solid #10b981; color: #10b981; }
.badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.badge-success { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.badge-warning { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
.badge-danger { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.badge-muted { background: var(--bg-secondary); color: var(--text-muted); }
.spinner { animation: spin 1s linear infinite; }
</style>