<template>
  <div class="animate-fade-in">
    <h1>角色與權限管理</h1>
    <p class="subtitle">指派系統角色（ADMIN / MANAGER / SALES / STAFF）與超級管理員設定</p>

    <!-- Success/Error Messages -->
    <div v-if="successMessage" class="alert alert-success">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      {{ successMessage }}
    </div>
    <div v-if="errorMessage" class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
      {{ errorMessage }}
    </div>

    <!-- Role Legend -->
    <div class="glass-card mb-4">
      <h2>角色說明</h2>
      <div class="role-legend-grid">
        <div class="role-legend-item">
          <span class="role-badge role-owner">負責人 OWNER</span>
          <p>擁有系統最高權限，可指派所有角色，負責所有資料。</p>
        </div>
        <div class="role-legend-item">
          <span class="role-badge role-admin">系統管理員 ADMIN</span>
          <p>可管理所有資料庫資料、操作 RBAC，適合 IT 管理員。</p>
        </div>
        <div class="role-legend-item">
          <span class="role-badge role-manager">主管 MANAGER</span>
          <p>可檢視所有報表、核准下屬假單、操作銷貨與託售。</p>
        </div>
        <div class="role-legend-item">
          <span class="role-badge role-sales">業務 SALES</span>
          <p>可操作銷貨、客戶管理、託售叫貨，不能訪問 /api/db。</p>
        </div>
        <div class="role-legend-item">
          <span class="role-badge role-staff">一般員工 STAFF</span>
          <p>基本權限，可打卡、請假，檢視自己的資料。</p>
        </div>
      </div>
    </div>

    <!-- Employee Role Table -->
    <div class="glass-card">
      <div class="table-header">
        <h2>員工角色一覽</h2>
        <button class="btn btn-secondary" @click="loadEmployees" :disabled="loadingEmployees">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
          重新整理
        </button>
      </div>

      <div v-if="loadingEmployees" class="loading-state">載入中...</div>

      <table v-else>
        <thead>
          <tr>
            <th>員工編號</th>
            <th>姓名</th>
            <th>目前角色</th>
            <th>超級管理員</th>
            <th>狀態</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="emp in employees" :key="emp.id">
            <td>
              <span class="emp-code">{{ emp.code }}</span>
            </td>
            <td>{{ emp.name }}</td>
            <td>
              <span :class="'role-badge role-' + (emp.role || 'staff').toLowerCase()">
                {{ roleLabel(emp.role) }}
              </span>
            </td>
            <td>
              <span :class="emp.is_superuser ? 'text-success' : 'text-muted'">
                {{ emp.is_superuser ? '✅ 是' : '❌ 否' }}
              </span>
            </td>
            <td>
              <span :class="'badge badge-' + (emp.is_active ? 'success' : 'muted')">
                {{ emp.is_active ? '在職' : '離職' }}
              </span>
            </td>
            <td>
              <button
                class="btn-icon"
                @click="openRoleModal(emp)"
                :disabled="!canEditRole(emp)"
                title="編輯角色"
              >
                變更角色
              </button>
            </td>
          </tr>
          <tr v-if="employees.length === 0">
            <td colspan="6" class="text-center text-muted">目前尚無員工資料</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Role Edit Modal -->
    <div class="modal-backdrop" v-if="showRoleModal">
      <div class="modal-card glass-card">
        <h3>變更角色 — {{ editingEmployee?.name }}</h3>
        <div class="modal-form">
          <div class="form-group">
            <label>新角色</label>
            <select v-model="roleForm.role">
              <option value="OWNER">負責人 (OWNER)</option>
              <option value="ADMIN">系統管理員 (ADMIN)</option>
              <option value="MANAGER">主管 (MANAGER)</option>
              <option value="SALES">業務 (SALES)</option>
              <option value="STAFF">一般員工 (STAFF)</option>
            </select>
          </div>
          <div class="form-group">
            <label>
              <input type="checkbox" v-model="roleForm.is_superuser" />
              超級管理員（可訪問 /api/db 所有端點）
            </label>
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="showRoleModal = false">取消</button>
          <button class="btn btn-primary" @click="submitRoleChange" :disabled="submittingRole">
            <span v-if="submittingRole">儲存中...</span>
            <span v-else>儲存</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'RoleManagement',
  data() {
    return {
      employees: [],
      loadingEmployees: false,
      showRoleModal: false,
      editingEmployee: null,
      submittingRole: false,
      successMessage: '',
      errorMessage: '',
      roleForm: {
        role: 'STAFF',
        is_superuser: false
      }
    }
  },
  mounted() {
    this.loadEmployees()
  },
  methods: {
    async loadEmployees() {
      this.loadingEmployees = true
      this.successMessage = ''
      this.errorMessage = ''
      try {
        const res = await supabase.from('erp_employees/')
        this.employees = res.data
      } catch (err) {
        this.errorMessage = '載入員工失敗：' + (err.response?.data?.detail || err.message)
      } finally {
        this.loadingEmployees = false
      }
    },
    roleLabel(role) {
      const map = { OWNER: '負責人', MANAGER: '主管', ADMIN: '系統管理員', SALES: '業務', STAFF: '一般員工' }
      return map[role] || role || '一般員工'
    },
    canEditRole(emp) {
      const currentUser = JSON.parse(localStorage.getItem('user') || '{}')
      const currentRole = (currentUser.role || '').toUpperCase()
      if (currentRole === 'OWNER') return true
      if (currentRole === 'ADMIN' && emp.role !== 'OWNER') return true
      return false
    },
    openRoleModal(emp) {
      this.editingEmployee = emp
      this.roleForm = {
        role: emp.role || 'STAFF',
        is_superuser: !!emp.is_superuser
      }
      this.showRoleModal = true
    },
    async submitRoleChange() {
      if (!this.editingEmployee) return
      this.submittingRole = true
      this.successMessage = ''
      this.errorMessage = ''
      try {
        await this.$api.patch(`/employees/${this.editingEmployee.id}/role`, {
          role: this.roleForm.role,
          is_superuser: this.roleForm.is_superuser
        })
        this.successMessage = `已將 ${this.editingEmployee.name} 的角色變更為 ${this.roleLabel(this.roleForm.role)}`
        this.showRoleModal = false
        await this.loadEmployees()
        setTimeout(() => { this.successMessage = '' }, 5000)
      } catch (err) {
        this.errorMessage = err.response?.data?.detail || '變更失敗：' + err.message
        setTimeout(() => { this.errorMessage = '' }, 5000)
      } finally {
        this.submittingRole = false
      }
    }
  }
}
</script>

<style scoped>
.role-legend-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}
.role-legend-item {
  padding: 0.75rem;
  border: 1px solid var(--border-glass);
  border-radius: 8px;
}
.role-legend-item p {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin: 0.4rem 0 0;
}
.emp-code {
  font-family: monospace;
  font-weight: 600;
  color: var(--color-primary);
}
.text-success { color: var(--color-success, #10b981); }
.text-muted { color: var(--text-muted); }
.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}
.table-header h2 { margin: 0; }
.mb-4 { margin-bottom: 1.5rem; }
.modal-backdrop {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.7); backdrop-filter: blur(4px);
  display: flex; align-items: center; justify-content: center; z-index: 1000;
}
.modal-card { width: 90%; max-width: 420px; }
.modal-actions {
  display: flex; justify-content: flex-end; gap: 1rem;
  border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem;
}
.role-badge {
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: 600;
}
.role-owner { background: #ffd70033; color: #ffd700; }
.role-admin { background: #ef444433; color: #ef4444; }
.role-manager { background: #3b82f633; color: #3b82f6; }
.role-sales { background: #10b98133; color: #10b981; }
.role-staff { background: rgba(255,255,255,0.08); color: var(--text-muted); }
</style>
