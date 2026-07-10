<template>
  <div class="page-container animate-fade-in">
    <div class="page-header">
      <h1>⭐ 會員等級管理中心</h1>
      <p class="subtitle">設定金卡、銀卡、一般會員的等級名稱與對應折扣率</p>
    </div>

    <!-- Action Bar -->
    <div class="glass-card" style="margin-bottom: 1.5rem;">
      <div class="action-bar">
        <div>
          <span class="stat-summary">
            共 <strong>{{ tiers.length }}</strong> 個等級
          </span>
        </div>
        <button class="btn btn-primary" @click="openForm(null)">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          新增等級
        </button>
      </div>
    </div>

    <!-- Tiers Table -->
    <div class="glass-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>代碼</th>
            <th>等級名稱</th>
            <th>折扣率</th>
            <th>實收比例</th>
            <th>說明</th>
            <th>狀態</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="7" class="text-center text-muted" style="padding: 2rem;">載入中...</td>
          </tr>
          <tr v-else-if="tiers.length === 0">
            <td colspan="7" class="text-center text-muted" style="padding: 2rem;">尚無會員等級設定</td>
          </tr>
          <tr v-else v-for="tier in tiers" :key="tier.id">
            <td><span class="code-badge">{{ tier.code }}</span></td>
            <td><strong>{{ tier.name }}</strong></td>
            <td>
              <span class="discount-badge">{{ (tier.discount_rate * 100).toFixed(0) }} 折</span>
              <span class="discount-value">({{ (tier.discount_rate * 100).toFixed(1) }}%)</span>
            </td>
            <td>
              <div class="rate-bar-container">
                <div class="rate-bar" :style="{ width: (tier.discount_rate * 100) + '%', background: tierColor(tier.code) }"></div>
                <span class="rate-label">{{ (tier.discount_rate * 100).toFixed(0) }}%</span>
              </div>
            </td>
            <td class="text-muted">{{ tier.description || '-' }}</td>
            <td>
              <span v-if="tier.is_active" class="badge badge-success">啟用</span>
              <span v-else class="badge badge-secondary">停用</span>
            </td>
            <td>
              <button class="btn-link" @click="openForm(tier)">編輯</button>
              <button v-if="tier.is_active" class="btn-link" style="color: #ef4444; margin-left: 0.5rem;" @click="deleteTier(tier)">停用</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Form Dialog -->
    <div class="modal-backdrop" v-if="showForm">
      <div class="modal-card glass-card">
        <h3>{{ isEditing ? '編輯等級' : '新增等級' }}</h3>
        <div class="form-body">
          <div class="form-group">
            <label>等級代碼 * <span class="hint">（如 GOLD、SILVER、STANDARD）</span></label>
            <input type="text" v-model="form.code" required :disabled="isEditing" placeholder="例如: GOLD" />
          </div>
          <div class="form-group">
            <label>等級名稱 *</label>
            <input type="text" v-model="form.name" required placeholder="例如: 金卡會員" />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>折扣率 * <span class="hint">（0.90 = 9折）</span></label>
              <input type="number" v-model.number="form.discount_rate" min="0" max="1" step="0.01" required />
              <div class="discount-preview">
                實收 {{ ((form.discount_rate || 1) * 100).toFixed(0) }}% = {{ form.discount_rate || 1 }} 倍
              </div>
            </div>
          </div>
          <div class="form-group">
            <label>說明</label>
            <input type="text" v-model="form.description" placeholder="選填，描述此等級的適用場景" />
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeForm">取消</button>
          <button class="btn btn-primary" @click="saveTier" :disabled="saving || !form.code || !form.name">
            {{ saving ? '儲存中...' : '儲存' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'MemberTiers',
  data() {
    return {
      tiers: [],
      loading: false,
      showForm: false,
      isEditing: false,
      saving: false,
      form: this.getEmptyForm()
    }
  },
  mounted() {
    this.fetchTiers()
  },
  methods: {
    getEmptyForm() {
      return {
        tenant_id: 1,
        code: '',
        name: '',
        discount_rate: 1.0,
        description: ''
      }
    },
    async fetchTiers() {
      this.loading = true
      try {
        const res = await supabase.from('erp_member-tiers/')
        this.tiers = res.data
      } catch (err) {
        console.error('Failed to load tiers:', err)
        alert('載入失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.loading = false
      }
    },
    openForm(tier) {
      if (tier) {
        this.isEditing = true
        this.form = {
          code: tier.code,
          name: tier.name,
          discount_rate: tier.discount_rate,
          description: tier.description || ''
        }
      } else {
        this.isEditing = false
        this.form = this.getEmptyForm()
      }
      this.showForm = true
    },
    closeForm() {
      this.showForm = false
    },
    async saveTier() {
      if (!this.form.code || !this.form.name) {
        alert('請填寫代碼和名稱')
        return
      }
      this.saving = true
      try {
        if (this.isEditing) {
          // Find tier by code
          const tier = this.tiers.find(t => t.code === this.form.code)
          if (!tier) throw new Error('等級不存在')
          await this.$api.put(`/member-tiers/${tier.id}`, this.form)
          alert('更新成功！')
        } else {
          await supabase.from('erp_member-tiers/', {
            tenant_id: 1,
            ...this.form
          })
          alert('建立成功！')
        }
        this.closeForm()
        this.fetchTiers()
      } catch (err) {
        alert('儲存失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.saving = false
      }
    },
    async deleteTier(tier) {
      if (!confirm(`確定要停用「${tier.name}」？已使用此等級的會員不受影響。`)) return
      try {
        await this.$api.delete(`/member-tiers/${tier.id}`)
        alert('已停用')
        this.fetchTiers()
      } catch (err) {
        alert('停用失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    tierColor(code) {
      const colors = {
        'GOLD': '#eab308',
        'SILVER': '#94a3b8',
        'STANDARD': '#6366f1',
        'PLATINUM': '#a855f7',
        'DIAMOND': '#06b6d4'
      }
      return colors[code?.toUpperCase()] || '#6366f1'
    }
  }
}
</script>

<style scoped>
.page-container { padding: 2rem; max-width: 1200px; margin: 0 auto; }
.page-header { margin-bottom: 1.5rem; }
.page-header h1 { font-size: 2rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem; }
.subtitle { color: var(--text-secondary); font-size: 0.95rem; }

.action-bar { display: flex; justify-content: space-between; align-items: center; }
.stat-summary { color: var(--text-muted); font-size: 0.9rem; }
.stat-summary strong { color: var(--text-primary); }

.data-table { width: 100%; border-collapse: collapse; }
.data-table th {
  text-align: left;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--border-glass);
  color: var(--text-muted);
  font-weight: 600;
  font-size: 0.85rem;
}
.data-table td { padding: 0.85rem 1rem; border-bottom: 1px solid rgba(255,255,255,0.03); }
.data-table tr:hover { background: rgba(255,255,255,0.02); }
.text-center { text-align: center; }
.text-muted { color: var(--text-muted); font-size: 0.9rem; }

.code-badge {
  font-family: 'SF Mono', 'Fira Code', monospace;
  font-size: 0.85rem;
  font-weight: 700;
  background: rgba(99,102,241,0.15);
  color: #a78bfa;
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
}
.discount-badge {
  font-weight: 700;
  color: #eab308;
  font-size: 1rem;
}
.discount-value { color: var(--text-muted); font-size: 0.8rem; margin-left: 0.3rem; }

.rate-bar-container { position: relative; height: 8px; background: rgba(255,255,255,0.08); border-radius: 4px; margin-top: 0.5rem; max-width: 120px; }
.rate-bar { height: 100%; border-radius: 4px; transition: width 0.3s; }
.rate-label { position: absolute; right: 0; top: -18px; font-size: 0.75rem; color: var(--text-muted); }

.btn { display: inline-flex; align-items: center; gap: 0.4rem; padding: 0.5rem 1rem; border: none; border-radius: var(--radius-button); font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.btn-primary { background: var(--color-primary); color: white; }
.btn-primary:hover { opacity: 0.9; }
.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }
.btn-secondary { background: rgba(255,255,255,0.1); color: var(--text-primary); }
.btn-secondary:hover { background: rgba(255,255,255,0.15); }
.btn-link { background: none; border: none; color: var(--color-primary); font-size: 0.85rem; font-weight: 600; cursor: pointer; padding: 0; }
.btn-link:hover { text-decoration: underline; }

.badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; }
.badge-success { background: rgba(34,197,94,0.15); color: #22c55e; }
.badge-secondary { background: rgba(255,255,255,0.08); color: var(--text-muted); }

/* Modal */
.modal-backdrop { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-card { width: 90%; max-width: 480px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); padding: 1.5rem; }
.modal-card h3 { margin-bottom: 1.25rem; color: var(--text-primary); }
.modal-actions { display: flex; justify-content: flex-end; gap: 0.75rem; border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem; }

.form-body { display: flex; flex-direction: column; gap: 1rem; }
.form-row { display: grid; grid-template-columns: 1fr; gap: 1rem; }
.form-group { display: flex; flex-direction: column; gap: 0.4rem; }
.form-group label { font-size: 0.85rem; font-weight: 600; color: var(--text-muted); }
.form-group .hint { font-weight: 400; color: var(--text-muted); font-size: 0.8rem; }
.form-group input {
  padding: 0.6rem 0.85rem;
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  background: rgba(255,255,255,0.05);
  color: var(--text-primary);
  font-size: 0.9rem;
}
.form-group input:focus { outline: none; border-color: var(--color-primary); }
.form-group input:disabled { opacity: 0.6; cursor: not-allowed; }
.discount-preview { font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem; }
</style>