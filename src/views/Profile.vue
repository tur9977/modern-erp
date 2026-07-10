<template>
  <div class="animate-fade-in">
    <h1>個人設定</h1>
    <p class="subtitle">修改密碼與個人資訊檢視</p>

    <div v-if="successMessage" class="alert alert-success">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      {{ successMessage }}
    </div>
    <div v-if="errorMessage" class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
      {{ errorMessage }}
    </div>

    <div class="grid-cols-2">
      <!-- Profile Info Card -->
      <div class="glass-card">
        <h2>個人資訊</h2>
        <div class="profile-grid">
          <div class="profile-avatar">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          </div>
          <div class="profile-info">
            <div class="profile-item">
              <label>員工編號</label>
              <span>{{ user.code }}</span>
            </div>
            <div class="profile-item">
              <label>姓名</label>
              <span>{{ user.name }}</span>
            </div>
            <div class="profile-item">
              <label>角色</label>
              <span :class="'role-badge role-' + (user.role || 'STAFF').toLowerCase()">
                {{ roleLabel(user.role) }}
              </span>
            </div>
            <div class="profile-item">
              <label>超級管理員</label>
              <span>{{ user.is_superuser ? '是' : '否' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Change Password Card -->
      <div class="glass-card">
        <h2>修改密碼</h2>
        <form @submit.prevent="submitPasswordChange">
          <div class="form-group password-field">
            <label>目前密碼 <span class="required">*</span></label>
            <div class="input-with-toggle">
              <input
                :type="showOldPassword ? 'text' : 'password'"
                v-model="passwordForm.old_password"
                required
                placeholder="請輸入目前密碼"
                autocomplete="current-password"
              />
              <button type="button" class="toggle-visibility" @click="showOldPassword = !showOldPassword" :title="showOldPassword ? '隱藏密碼' : '顯示密碼'">
                <svg v-if="!showOldPassword" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-8-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a21.78 21.78 0 0 0 5.39 11.17"/><path d="M1 1l22 22"/><path d="M14.12 14.12a3 3 0 0 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
          </div>
          <div class="form-group password-field">
            <label>新密碼 <span class="required">*</span></label>
            <div class="input-with-toggle">
              <input
                :type="showNewPassword ? 'text' : 'password'"
                v-model="passwordForm.new_password"
                required
                placeholder="請輸入新密碼（至少 8 碼）"
                autocomplete="new-password"
                minlength="8"
              />
              <button type="button" class="toggle-visibility" @click="showNewPassword = !showNewPassword" :title="showNewPassword ? '隱藏密碼' : '顯示密碼'">
                <svg v-if="!showNewPassword" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-8-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a21.78 21.78 0 0 0 5.39 11.17"/><path d="M1 1l22 22"/><path d="M14.12 14.12a3 3 0 0 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
          </div>
          <div class="form-group password-field">
            <label>確認新密碼 <span class="required">*</span></label>
            <div class="input-with-toggle">
              <input
                :type="showConfirmPassword ? 'text' : 'password'"
                v-model="passwordForm.confirm_password"
                required
                placeholder="再次輸入新密碼"
                autocomplete="new-password"
                minlength="8"
              />
              <button type="button" class="toggle-visibility" @click="showConfirmPassword = !showConfirmPassword" :title="showConfirmPassword ? '隱藏密碼' : '顯示密碼'">
                <svg v-if="!showConfirmPassword" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-8-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a21.78 21.78 0 0 0 5.39 11.17"/><path d="M1 1l22 22"/><path d="M14.12 14.12a3 3 0 0 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
          </div>
            <small v-if="passwordForm.new_password && passwordForm.confirm_password && passwordForm.new_password !== passwordForm.confirm_password" class="field-error">
              兩次輸入的密碼不一致
            </small>
          <button
            type="submit"
            class="btn btn-primary"
            :disabled="submitting || passwordForm.new_password !== passwordForm.confirm_password"
          >
            <span v-if="submitting">修改中...</span>
            <span v-else>確認修改</span>
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'Profile',
  data() {
    return {
      user: {},
      submitting: false,
      successMessage: '',
      errorMessage: '',
      showOldPassword: false,
      showNewPassword: false,
      showConfirmPassword: false,
      passwordForm: {
        old_password: '',
        new_password: '',
        confirm_password: ''
      }
    }
  },
  mounted() {
    this.loadUser()
  },
  methods: {
    loadUser() {
      const stored = localStorage.getItem('user')
      if (stored) {
        try {
          this.user = JSON.parse(stored)
        } catch (e) {
          console.error('Failed to parse stored user:', e)
        }
      }
    },
    roleLabel(role) {
      const map = { OWNER: '負責人', MANAGER: '主管', SALES: '業務', STAFF: '一般員工', ADMIN: '系統管理員' }
      return map[role] || role || '一般員工'
    },
    async submitPasswordChange() {
      this.successMessage = ''
      this.errorMessage = ''
      if (!this.passwordForm.old_password || !this.passwordForm.new_password) return
      if (this.passwordForm.new_password !== this.passwordForm.confirm_password) return
      if (this.passwordForm.new_password.length < 8) {
        this.errorMessage = '新密碼至少需要 8 個字元'
        return
      }
      this.submitting = true
      try {
        await supabase.from('erp_auth/change-password', {
          old_password: this.passwordForm.old_password,
          new_password: this.passwordForm.new_password
        })
        this.successMessage = '密碼修改成功！請牢記您的新密碼。'
        this.passwordForm = { old_password: '', new_password: '', confirm_password: '' }
        setTimeout(() => { this.successMessage = '' }, 5000)
      } catch (err) {
        this.errorMessage = err.response?.data?.detail || '修改失敗：' + err.message
        setTimeout(() => { this.errorMessage = '' }, 5000)
      } finally {
        this.submitting = false
      }
    }
  }
}
</script>

<style scoped>
.profile-grid {
  display: flex;
  gap: 2rem;
  align-items: flex-start;
  margin-top: 1rem;
}
.profile-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-primary), #06b6d4);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  flex-shrink: 0;
}
.profile-info { flex: 1; }
.profile-item {
  display: flex;
  gap: 1rem;
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--border-glass);
}
.profile-item label {
  font-weight: 600;
  min-width: 100px;
  color: var(--text-muted);
}
.role-badge {
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
}
.role-owner { background: #ffd70033; color: #ffd700; }
.role-manager { background: #3b82f633; color: #3b82f6; }
.role-admin { background: #ef444433; color: #ef4444; }
.role-sales { background: #10b98133; color: #10b981; }
.role-staff { background: rgba(255,255,255,0.1); color: var(--text-muted); }
.field-error {
  color: var(--color-danger);
  font-size: 0.8rem;
  margin-top: 0.25rem;
  display: block;
}
.required { color: var(--color-danger); }
.password-field { position: relative; }
.input-with-toggle {
  position: relative;
  display: flex;
  align-items: center;
}
.input-with-toggle input {
  flex: 1;
  padding-right: 2.5rem;
}
.toggle-visibility {
  position: absolute;
  right: 0.6rem;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--text-muted);
  padding: 0.2rem;
  display: flex;
  align-items: center;
}
.toggle-visibility:hover { color: var(--color-primary); }
</style>
