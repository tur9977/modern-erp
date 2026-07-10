<template>
  <div class="animate-fade-in">
    <h1>出勤打卡</h1>
    <p class="subtitle">DOUBLE ERP 員工上下班打卡系統</p>

    <!-- Error/Success Messages -->
    <div v-if="errorMessage" class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
      {{ errorMessage }}
    </div>
    <div v-if="successMessage" class="alert alert-success">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      {{ successMessage }}
    </div>

    <!-- Current Employee & Status -->
    <div class="grid-cols-2">
      <!-- Employee Card -->
      <div class="glass-card">
        <h2 style="display: flex; align-items: center; gap: 0.5rem;">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          員工資訊
        </h2>
        <div class="employee-selector" v-if="!currentEmployee">
          <label>選擇員工</label>
          <select v-model="selectedEmployeeId" @change="selectEmployee">
            <option value="">-- 選擇員工 --</option>
            <option v-for="emp in employees" :key="emp.id" :value="emp.id">
              {{ emp.name }} ({{ emp.employee_no }})
            </option>
          </select>
        </div>
        <div class="employee-info" v-else>
          <div class="emp-avatar">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          </div>
          <div class="emp-details">
            <h3>{{ currentEmployee.name }}</h3>
            <p class="emp-no">員工編號: {{ currentEmployee.employee_no }}</p>
            <p class="emp-dept">{{ currentEmployee.department }} / {{ currentEmployee.position }}</p>
          </div>
          <button class="btn btn-outline btn-sm" @click="changeEmployee">切換員工</button>
        </div>
      </div>

      <!-- Attendance Status Card -->
      <div class="glass-card">
        <h2 style="display: flex; align-items: center; gap: 0.5rem;">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          今日出勤狀態
        </h2>
        <div class="status-display">
          <div class="status-indicator" :class="currentStatus?.status || 'off'">
            <div class="status-dot"></div>
            <span class="status-text">{{ statusLabel }}</span>
          </div>
          <div class="time-info" v-if="currentStatus">
            <div class="time-row" v-if="currentStatus.clock_in">
              <span class="time-label">上班打卡</span>
              <span class="time-value">{{ formatTime(currentStatus.clock_in) }}</span>
            </div>
            <div class="time-row" v-if="currentStatus.clock_out">
              <span class="time-label">下班打卡</span>
              <span class="time-value">{{ formatTime(currentStatus.clock_out) }}</span>
            </div>
            <div class="time-row" v-if="currentStatus.work_hours">
              <span class="time-label">工作時數</span>
              <span class="time-value">{{ currentStatus.work_hours }} 小時</span>
            </div>
          </div>
          <div class="no-record" v-else>
            <p>今日尚無打卡記錄</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Clock In/Out Buttons -->
    <div class="glass-card clock-section">
      <h2>打卡作業</h2>
      <div class="clock-buttons">
        <div class="clock-btn-group">
          <button class="clock-btn clock-in" @click="clockIn" :disabled="!currentEmployee || currentStatus?.clock_in || submitting">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>
            <span class="btn-text">上班打卡</span>
            <span class="btn-time">{{ nowTime }}</span>
          </button>
          <p class="clock-hint" v-if="!currentStatus?.clock_in">按下按鈕進行上班打卡</p>
          <p class="clock-success" v-else>已於 {{ formatTime(currentStatus.clock_in) }} 上班打卡</p>
        </div>
        <div class="clock-divider">
          <div class="divider-line"></div>
          <span class="divider-text">OR</span>
          <div class="divider-line"></div>
        </div>
        <div class="clock-btn-group">
          <button class="clock-btn clock-out" @click="clockOut" :disabled="!currentEmployee || !currentStatus?.clock_in || currentStatus?.clock_out || submitting">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            <span class="btn-text">下班打卡</span>
            <span class="btn-time">{{ nowTime }}</span>
          </button>
          <p class="clock-hint" v-if="currentStatus?.clock_in && !currentStatus?.clock_out">按下按鈕進行下班打卡</p>
          <p class="clock-success" v-if="currentStatus?.clock_out">已於 {{ formatTime(currentStatus.clock_out) }} 下班打卡</p>
          <p class="clock-warning" v-if="currentStatus?.clock_in && !currentStatus?.clock_out && isOvertime">已超過正常工時 8 小時</p>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="glass-card">
      <h2>其他出勤作業</h2>
      <div class="action-grid">
        <button class="action-btn" @click="showLeaveModal = true" :disabled="!currentEmployee">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          請假申請
        </button>
        <button class="action-btn" @click="showOvertimeModal = true" :disabled="!currentEmployee">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          加班登記
        </button>
        <button class="action-btn" @click="showBusinessModal = true" :disabled="!currentEmployee">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          公出登記
        </button>
        <button class="action-btn" @click="showAdjustModal = true" :disabled="!currentEmployee">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          補卡申請
        </button>
      </div>
    </div>

    <!-- Attendance Calendar / History -->
    <div class="glass-card">
      <div class="table-header">
        <h2>出勤記錄</h2>
        <div style="display: flex; gap: 0.5rem;">
          <select v-model="selectedMonth" @change="loadAttendanceHistory" style="padding: 0.5rem; border-radius: 6px; border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text);">
            <option v-for="m in monthOptions" :key="m.value" :value="m.value">{{ m.label }}</option>
          </select>
          <button class="btn btn-secondary" @click="loadAttendanceHistory" :disabled="loadingHistory">
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
            <th>日期</th>
            <th>星期</th>
            <th>上班時間</th>
            <th>下班時間</th>
            <th>工作時數</th>
            <th>狀態</th>
            <th>備註</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="record in attendanceHistory" :key="record.date">
            <td>{{ record.date }}</td>
            <td>{{ weekDayLabel(record.weekday) }}</td>
            <td>{{ record.clock_in ? formatTime(record.clock_in) : '-' }}</td>
            <td>{{ record.clock_out ? formatTime(record.clock_out) : '-' }}</td>
            <td>{{ record.work_hours ? record.work_hours + 'h' : '-' }}</td>
            <td>
              <span :class="'badge badge-' + attendanceStatusColor(record.status)">
                {{ attendanceStatusLabel(record.status) }}
              </span>
            </td>
            <td>{{ record.note || '' }}</td>
          </tr>
          <tr v-if="attendanceHistory.length === 0 && !loadingHistory">
            <td colspan="7" class="empty-row">
              <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                <p>目前沒有出勤記錄</p>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Leave Request Modal -->
    <div v-if="showLeaveModal" class="modal-overlay" @click.self="showLeaveModal = false">
      <div class="modal-content glass-card">
        <div class="modal-header">
          <h2>請假申請</h2>
          <button class="btn-icon" @click="showLeaveModal = false">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>假別</label>
            <select v-model="leaveForm.type">
              <option value="annual">特休假</option>
              <option value="sick">病假</option>
              <option value="personal">事假</option>
              <option value="unpaid">無薪假</option>
              <option value="other">其他</option>
            </select>
          </div>
          <div class="form-group">
            <label>起始日期</label>
            <input type="date" v-model="leaveForm.start_date" />
          </div>
          <div class="form-group">
            <label>結束日期</label>
            <input type="date" v-model="leaveForm.end_date" />
          </div>
          <div class="form-group">
            <label>時數 (小時)</label>
            <input type="number" v-model.number="leaveForm.hours" min="1" max="24" />
          </div>
          <div class="form-group">
            <label>原因</label>
            <textarea v-model="leaveForm.reason" rows="3" placeholder="請輸入請假原因..."></textarea>
          </div>
          <div style="display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem;">
            <button class="btn btn-secondary" @click="showLeaveModal = false">取消</button>
            <button class="btn btn-primary" @click="submitLeave" :disabled="submitting">送出申請</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Overtime Modal -->
    <div v-if="showOvertimeModal" class="modal-overlay" @click.self="showOvertimeModal = false">
      <div class="modal-content glass-card">
        <div class="modal-header">
          <h2>加班登記</h2>
          <button class="btn-icon" @click="showOvertimeModal = false">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>加班日期</label>
            <input type="date" v-model="overtimeForm.date" />
          </div>
          <div class="form-group">
            <label>加班時數</label>
            <input type="number" v-model.number="overtimeForm.hours" min="0.5" max="12" step="0.5" />
          </div>
          <div class="form-group">
            <label>加班原因</label>
            <textarea v-model="overtimeForm.reason" rows="3" placeholder="請輸入加班原因..."></textarea>
          </div>
          <div style="display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem;">
            <button class="btn btn-secondary" @click="showOvertimeModal = false">取消</button>
            <button class="btn btn-primary" @click="submitOvertime" :disabled="submitting">送出</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Business Trip Modal -->
    <div v-if="showBusinessModal" class="modal-overlay" @click.self="showBusinessModal = false">
      <div class="modal-content glass-card">
        <div class="modal-header">
          <h2>公出登記</h2>
          <button class="btn-icon" @click="showBusinessModal = false">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>公出日期</label>
            <input type="date" v-model="businessForm.date" />
          </div>
          <div class="form-group">
            <label>目的地</label>
            <input type="text" v-model="businessForm.location" placeholder="請輸入公出地點" />
          </div>
          <div class="form-group">
            <label>事由</label>
            <textarea v-model="businessForm.reason" rows="3" placeholder="請輸入公出事由..."></textarea>
          </div>
          <div style="display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem;">
            <button class="btn btn-secondary" @click="showBusinessModal = false">取消</button>
            <button class="btn btn-primary" @click="submitBusiness" :disabled="submitting">送出</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Adjust Modal -->
    <div v-if="showAdjustModal" class="modal-overlay" @click.self="showAdjustModal = false">
      <div class="modal-content glass-card">
        <div class="modal-header">
          <h2>補卡申請</h2>
          <button class="btn-icon" @click="showAdjustModal = false">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>補卡日期</label>
            <input type="date" v-model="adjustForm.date" />
          </div>
          <div class="form-group">
            <label>補卡類型</label>
            <select v-model="adjustForm.type">
              <option value="clock_in">補上班卡</option>
              <option value="clock_out">補下班卡</option>
              <option value="both">兩者皆補</option>
            </select>
          </div>
          <div class="form-group" v-if="adjustForm.type !== 'clock_out'">
            <label>補上班時間</label>
            <input type="time" v-model="adjustForm.clock_in_time" />
          </div>
          <div class="form-group" v-if="adjustForm.type !== 'clock_in'">
            <label>補下班時間</label>
            <input type="time" v-model="adjustForm.clock_out_time" />
          </div>
          <div class="form-group">
            <label>原因</label>
            <textarea v-model="adjustForm.reason" rows="3" placeholder="請輸入補卡原因..."></textarea>
          </div>
          <div style="display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1.5rem;">
            <button class="btn btn-secondary" @click="showAdjustModal = false">取消</button>
            <button class="btn btn-primary" @click="submitAdjust" :disabled="submitting">送出申請</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';

// Employee state
const employees = ref([]);
const currentEmployee = ref(null);
const selectedEmployeeId = ref('');

// Current status
const currentStatus = ref(null);

// Time
const nowTime = ref('');
let clockInterval = null;

// Attendance history
const attendanceHistory = ref([]);
const loadingHistory = ref(false);
const selectedMonth = ref('');

// Modals
const showLeaveModal = ref(false);
const showOvertimeModal = ref(false);
const showBusinessModal = ref(false);
const showAdjustModal = ref(false);

// UI state
const errorMessage = ref('');
const successMessage = ref('');
const submitting = ref(false);

// Forms
const leaveForm = ref({ type: 'annual', start_date: '', end_date: '', hours: 8, reason: '' });
const overtimeForm = ref({ date: '', hours: 2, reason: '' });
const businessForm = ref({ date: '', location: '', reason: '' });
const adjustForm = ref({ date: '', type: 'clock_in', clock_in_time: '', clock_out_time: '', reason: '' });

// Month options
const monthOptions = computed(() => {
  const opts = [];
  const now = new Date();
  for (let i = 0; i < 12; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    opts.push({
      value: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`,
      label: `${d.getFullYear()} 年 ${d.getMonth() + 1} 月`
    });
  }
  return opts;
});

// Computed
const statusLabel = computed(() => {
  if (!currentStatus.value) return '未打卡';
  if (currentStatus.value.clock_out) return '已下班';
  if (currentStatus.value.clock_in) return '工作中';
  return '未打卡';
});

const isOvertime = computed(() => {
  if (!currentStatus.value?.clock_in || currentStatus.value?.clock_out) return false;
  const now = new Date();
  const diff = (now - new Date(currentStatus.value.clock_in)) / (1000 * 60 * 60);
  return diff > 8;
});

function updateNowTime() {
  const now = new Date();
  nowTime.value = now.toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}

// Methods
function selectEmployee() {
  if (!selectedEmployeeId.value) {
    currentEmployee.value = null;
    currentStatus.value = null;
    return;
  }
  const emp = employees.value.find(e => e.id == selectedEmployeeId.value);
  currentEmployee.value = emp || null;
  if (emp) {
    loadTodayStatus();
    loadAttendanceHistory();
  }
}

function changeEmployee() {
  currentEmployee.value = null;
  currentStatus.value = null;
  selectedEmployeeId.value = '';
  attendanceHistory.value = [];
}

async function clockIn() {
  if (!currentEmployee.value) return;
  errorMessage.value = '';
  submitting.value = true;
  try {
    const res = await apiClient.post('/hr/attendance/clock-in', { employee_id: currentEmployee.value.id });
    const data = res.data;
    successMessage.value = `上班打卡成功！時間：${formatTime(data.clock_in)}`;
    await loadTodayStatus();
    setTimeout(() => { successMessage.value = ''; }, 5000);
  } catch (err) {
    errorMessage.value = err.response?.data?.message || err.message;
    setTimeout(() => { errorMessage.value = ''; }, 5000);
  } finally {
    submitting.value = false;
  }
}

async function clockOut() {
  if (!currentEmployee.value) return;
  errorMessage.value = '';
  submitting.value = true;
  try {
    const res = await apiClient.post('/hr/attendance/clock-out', { employee_id: currentEmployee.value.id });
    const data = res.data;
    successMessage.value = `下班打卡成功！時間：${formatTime(data.clock_out)}`;
    await loadTodayStatus();
    setTimeout(() => { successMessage.value = ''; }, 5000);
  } catch (err) {
    errorMessage.value = err.response?.data?.message || err.message;
    setTimeout(() => { errorMessage.value = ''; }, 5000);
  } finally {
    submitting.value = false;
  }
}

async function loadTodayStatus() {
  if (!currentEmployee.value) return;
  try {
    const res = await apiClient.get(`/hr/attendance/today?employee_id=${currentEmployee.value.id}`);
    currentStatus.value = res.data;
  } catch (err) {
    console.error('載入今日狀態失敗:', err);
  }
}

async function loadAttendanceHistory() {
  if (!currentEmployee.value) return;
  loadingHistory.value = true;
  try {
    const params = new URLSearchParams({ employee_id: currentEmployee.value.id });
    if (selectedMonth.value) params.append('month', selectedMonth.value);
    const res = await apiClient.get(`/hr/attendance/history?${params.toString()}`);
    attendanceHistory.value = res.data.records || res.data || [];
  } catch (err) {
    console.error('載入出勤記錄失敗:', err);
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

async function submitLeave() {
  if (!leaveForm.value.start_date || !leaveForm.value.end_date) {
    alert('請填寫起訖日期');
    return;
  }
  submitting.value = true;
  try {
    await apiClient.post('/hr/leave', { ...leaveForm.value, employee_id: currentEmployee.value.id });
    alert('請假申請已送出');
    showLeaveModal.value = false;
    leaveForm.value = { type: 'annual', start_date: '', end_date: '', hours: 8, reason: '' };
  } catch (err) {
    alert(err.message);
  } finally {
    submitting.value = false;
  }
}

async function submitOvertime() {
  if (!overtimeForm.value.date) { alert('請填寫加班日期'); return; }
  submitting.value = true;
  try {
    await apiClient.post('/hr/overtime', { ...overtimeForm.value, employee_id: currentEmployee.value.id });
    alert('加班登記已送出');
    showOvertimeModal.value = false;
    overtimeForm.value = { date: '', hours: 2, reason: '' };
  } catch (err) {
    alert(err.message);
  } finally {
    submitting.value = false;
  }
}

async function submitBusiness() {
  if (!businessForm.value.date || !businessForm.value.location) { alert('請填寫日期與地點'); return; }
  submitting.value = true;
  try {
    await apiClient.post('/hr/business-trip', { ...businessForm.value, employee_id: currentEmployee.value.id });
    alert('公出登記已送出');
    showBusinessModal.value = false;
    businessForm.value = { date: '', location: '', reason: '' };
  } catch (err) {
    alert(err.message);
  } finally {
    submitting.value = false;
  }
}

async function submitAdjust() {
  if (!adjustForm.value.date) { alert('請填寫補卡日期'); return; }
  submitting.value = true;
  try {
    await apiClient.post('/hr/attendance/adjust', { ...adjustForm.value, employee_id: currentEmployee.value.id });
    alert('補卡申請已送出');
    showAdjustModal.value = false;
    adjustForm.value = { date: '', type: 'clock_in', clock_in_time: '', clock_out_time: '', reason: '' };
  } catch (err) {
    alert(err.message);
  } finally {
    submitting.value = false;
  }
}

function formatTime(dt) {
  if (!dt) return '-';
  return new Date(dt).toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit' });
}

function weekDayLabel(d) {
  return ['日', '一', '二', '三', '四', '五', '六'][d] || '';
}

function attendanceStatusLabel(s) {
  return { normal: '正常', late: '遲到', early: '早退', absent: '缺勤', leave: '請假', overtime: '加班' }[s] || s;
}

function attendanceStatusColor(s) {
  return { normal: 'success', late: 'warning', early: 'warning', absent: 'danger', leave: 'info', overtime: 'muted' }[s] || 'muted';
}

// Lifecycle
onMounted(() => {
  updateNowTime();
  clockInterval = setInterval(updateNowTime, 1000);
  loadEmployees();

  const now = new Date();
  selectedMonth.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
});

onUnmounted(() => {
  if (clockInterval) clearInterval(clockInterval);
});
</script>

<style scoped>
.employee-selector { display: flex; flex-direction: column; gap: 0.5rem; }
.employee-info { display: flex; align-items: center; gap: 1.25rem; }
.emp-avatar { width: 72px; height: 72px; border-radius: 50%; background: linear-gradient(135deg, var(--color-primary) 0%, #06b6d4 100%); display: flex; align-items: center; justify-content: center; color: white; }
.emp-details { flex: 1; }
.emp-details h3 { margin: 0 0 0.25rem; }
.emp-no { font-family: monospace; color: var(--text-muted); margin: 0.25rem 0; }
.emp-dept { font-size: 0.9rem; color: var(--text-muted); margin: 0; }
.status-display { padding: 1rem 0; }
.status-indicator { display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1.5rem; }
.status-dot { width: 14px; height: 14px; border-radius: 50%; background: #888; }
.status-indicator.work .status-dot { background: #10b981; box-shadow: 0 0 8px #10b981; }
.status-indicator.off .status-dot { background: #888; }
.status-indicator.offwork .status-dot { background: #6366f1; }
.status-text { font-size: 1.25rem; font-weight: 600; }
.status-indicator.work .status-text { color: #10b981; }
.status-indicator.off .status-text { color: var(--text-muted); }
.status-indicator.offwork .status-text { color: #6366f1; }
.time-info { display: flex; flex-direction: column; gap: 0.5rem; }
.time-row { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border-color); }
.time-row:last-child { border-bottom: none; }
.time-label { color: var(--text-muted); }
.time-value { font-weight: 600; }
.no-record { color: var(--text-muted); text-align: center; padding: 2rem; }
.clock-section { margin: 1.5rem 0; }
.clock-buttons { display: flex; align-items: center; gap: 2rem; padding: 2rem 0; }
.clock-btn-group { flex: 1; text-align: center; }
.clock-btn { display: flex; flex-direction: column; align-items: center; gap: 0.75rem; padding: 2rem; border: 2px solid var(--border-color); border-radius: 16px; cursor: pointer; transition: all 0.3s; min-width: 200px; background: var(--bg-secondary); }
.clock-btn:hover:not(:disabled) { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.3); }
.clock-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }
.clock-in { border-color: #10b981; color: #10b981; }
.clock-in:hover:not(:disabled) { background: rgba(16, 185, 129, 0.1); }
.clock-out { border-color: #ef4444; color: #ef4444; }
.clock-out:hover:not(:disabled) { background: rgba(239, 68, 68, 0.1); }
.btn-text { font-size: 1.1rem; font-weight: 700; }
.btn-time { font-size: 0.9rem; opacity: 0.8; font-family: monospace; }
.clock-hint { color: var(--text-muted); font-size: 0.9rem; margin-top: 0.75rem; }
.clock-success { color: #10b981; font-size: 0.9rem; margin-top: 0.75rem; }
.clock-warning { color: #f59e0b; font-size: 0.9rem; margin-top: 0.75rem; }
.clock-divider { display: flex; align-items: center; gap: 1rem; }
.divider-line { flex: 1; height: 2px; background: var(--border-color); }
.divider-text { color: var(--text-muted); font-size: 0.8rem; font-weight: 600; }
.action-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 1rem; }
.action-btn { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; padding: 1.25rem; border: 1px solid var(--border-color); border-radius: 12px; background: var(--bg-secondary); cursor: pointer; transition: all 0.2s; color: var(--text); }
.action-btn:hover:not(:disabled) { border-color: var(--color-primary); background: rgba(99, 102, 241, 0.05); }
.action-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.action-btn svg { color: var(--color-primary); }
.table-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
.loading-state { display: flex; flex-direction: column; align-items: center; padding: 3rem; color: var(--text-muted); }
.loading-state .spinner { animation: spin 1s linear infinite; margin-bottom: 1rem; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; padding: 3rem; color: var(--text-muted); }
.empty-state svg { opacity: 0.3; margin-bottom: 1rem; }
.empty-row td { padding: 2rem !important; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-content { width: 90%; max-width: 500px; max-height: 85vh; overflow-y: auto; padding: 0; }
.modal-header { display: flex; justify-content: space-between; align-items: center; padding: 1.25rem 1.5rem; border-bottom: 1px solid var(--border-color); }
.modal-header h2 { margin: 0; font-size: 1.1rem; }
.modal-body { padding: 1.5rem; }
.form-group { margin-bottom: 1.25rem; }
.form-group label { display: block; margin-bottom: 0.4rem; font-size: 0.9rem; color: var(--text-muted); }
.form-group input, .form-group select, .form-group textarea { width: 100%; padding: 0.65rem; border: 1px solid var(--border-color); border-radius: 6px; background: var(--bg-secondary); color: var(--text); font-size: 0.95rem; }
.form-group textarea { resize: vertical; }
.alert { display: flex; align-items: center; gap: 0.75rem; padding: 1rem; border-radius: 8px; margin-bottom: 1rem; }
.alert-error { background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; color: #ef4444; }
.alert-success { background: rgba(16, 185, 129, 0.15); border: 1px solid #10b981; color: #10b981; }
.badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.badge-success { background: rgba(16, 185, 129, 0.15); color: #10b981; }
.badge-warning { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
.badge-danger { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
.badge-info { background: rgba(99, 102, 241, 0.15); color: #6366f1; }
.badge-muted { background: var(--bg-secondary); color: var(--text-muted); }
</style>