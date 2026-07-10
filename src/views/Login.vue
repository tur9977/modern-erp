<template>
  <div class="login-page">
    <div class="login-card glass-card">
      <h1>DOUBLE ERP 登入</h1>
      <p class="subtitle">束胸製造與多零售通路 ERP 系統</p>
      <form @submit.prevent="submitLogin">
        <div class="form-group">
          <label>員工編號</label>
          <input type="text" v-model="form.code" required autofocus placeholder="例: EMP001" />
        </div>
        <div class="form-group">
          <label>密碼</label>
          <input type="password" v-model="form.password" required placeholder="請輸入密碼" />
        </div>
        <button type="submit" class="btn btn-primary" :disabled="loading" style="width: 100%;">
          {{ loading ? '登入中...' : '登入' }}
        </button>
        <p v-if="error" class="error-message">{{ error }}</p>
      </form>
        <p class="hint">測試帳號: neal / tur872104</p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Login',
  data() {
    return {
      form: { code: '', password: '' },
      loading: false,
      error: ''
    }
  },
  methods: {
    async submitLogin() {
      this.loading = true
      this.error = ''
      
      // Simulate API call
      setTimeout(() => {
        if (this.form.code === 'neal' && this.form.password === 'tur872104') {
          localStorage.setItem('access_token', 'dummy_token')
          localStorage.setItem('user', JSON.stringify({ code: 'neal', name: 'Neal' }))
          this.$router.push('/')
        } else {
          this.error = '帳號或密碼錯誤'
        }
        this.loading = false
      }, 500)
    }
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-main);
  padding: 1rem;
}
.login-card {
  width: 100%;
  max-width: 420px;
  padding: 2.5rem;
}
.subtitle {
  color: var(--text-muted);
  margin-bottom: 2rem;
  font-size: 0.9rem;
}
.form-group {
  margin-bottom: 1.2rem;
}
.form-group label {
  display: block;
  margin-bottom: 0.4rem;
  font-weight: 600;
  font-size: 0.9rem;
}
.form-group input {
  width: 100%;
  padding: 0.7rem;
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  background: var(--bg-input);
  color: var(--text-main);
  font-size: 1rem;
}
.btn-primary {
  background: var(--color-primary);
  color: #fff;
  border: none;
  padding: 0.8rem 1.5rem;
  border-radius: var(--radius-input);
  font-weight: 600;
  cursor: pointer;
  margin-top: 0.5rem;
}
.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.error-message {
  color: var(--color-danger);
  margin-top: 1rem;
  text-align: center;
  font-size: 0.9rem;
}
.hint {
  color: var(--text-muted);
  font-size: 0.8rem;
  text-align: center;
  margin-top: 1.5rem;
}
</style>
