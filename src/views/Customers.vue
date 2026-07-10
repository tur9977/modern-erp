<template>
  <div class="animate-fade-in">
    <h1>CRM 客戶管理</h1>
    <p class="subtitle">客戶資料管理、通路歸屬設定、會員資料查詢</p>

    <!-- 功能按鈕列 -->
    <div style="display:flex; gap: 1rem; margin-bottom: 1.5rem;">
      <button class="btn btn-primary" @click="openCustomerForm(null)">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:0.5rem;"><path d="M12 5v14M5 12h14"/></svg>
        新增會員
      </button>
      <div class="form-group" style="margin-bottom:0; flex: 1;">
        <input type="text" v-model="searchQuery" placeholder="搜尋代碼、姓名、電話、Email..." style="margin-bottom: 0;" />
      </div>
      <select v-model="filterType" style="padding: 0.5rem; border-radius: var(--radius-input);">
        <option value="">全部類型</option>
        <option value="RETAIL">一般會員</option>
        <option value="AGENT">代理商</option>
        <option value="CHANNEL">通路商</option>
      </select>
    </div>

    <!-- 客戶列表 -->
    <div class="glass-card">
      <table>
        <thead>
          <tr>
            <th>代號</th>
            <th>姓名/名稱</th>
            <th>類型</th>
            <th>等級</th>
            <th>電話</th>
            <th>紅利</th>
            <th>通路</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in filteredCustomers" :key="c.id">
            <td><span class="customer-code">{{ c.code }}</span></td>
            <td><strong>{{ c.name }}</strong></td>
            <td>
              <span class="badge" :class="typeBadgeClass(c.type)">
                {{ typeLabel(c.type) }}
              </span>
            </td>
            <td>
              <span v-if="c.tier_id" class="tier-badge">{{ getTierName(c.tier_id) }}</span>
              <span v-else class="text-muted">-</span>
            </td>
            <td>{{ c.phone || '-' }}</td>
            <td>
              <span v-if="c.points > 0" style="color: #eab308; font-weight: 600;">{{ c.points }}</span>
              <span v-else class="text-muted">0</span>
            </td>
            <td>{{ getChannelName(c.channel_id) }}</td>
            <td>
              <button class="btn-link" @click="openCustomerForm(c)">編輯</button>
              <button class="btn-link" style="color: var(--color-danger); margin-left: 0.5rem;" @click="deleteCustomer(c)">刪除</button>
            </td>
          </tr>
          <tr v-if="filteredCustomers.length === 0">
            <td colspan="9" style="text-align:center; color: var(--text-muted); padding: 2rem;">
              找不到符合條件的客戶
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- 客戶表單 Modal (極簡改良版) -->
    <div class="modal-backdrop" v-if="showForm">
      <div class="modal-card glass-card" style="max-width: 650px;">
        <h3>{{ isEditing ? '編輯會員資料' : '新增會員資料' }}</h3>
        
        <div class="modal-form" style="max-height: 65vh; overflow-y: auto; padding-right: 1rem;">
          
          <div style="border-bottom: 1px solid var(--border-glass); padding-bottom: 1rem; margin-bottom: 1rem;">
            <h4 style="color: var(--primary-color); margin-top: 0; margin-bottom: 0.8rem;">基本聯絡資訊</h4>
            <div class="grid-cols-2">
              <div class="form-group">
                <label>會員代號 *</label>
                <input type="text" v-model="form.code" required :disabled="isEditing" style="font-weight: 600; color: var(--color-primary);" />
              </div>
              <div class="form-group">
                <label>會員類型 *</label>
                <select v-model="form.type" required @change="onTypeChanged">
                  <option value="RETAIL">一般會員</option>
                  <option value="AGENT">代理商</option>
                  <option value="CHANNEL">通路商</option>
                </select>
              </div>
            </div>

            <div class="grid-cols-2">
              <div class="form-group">
                <label>姓名/名稱 *</label>
                <input type="text" v-model="form.name" required placeholder="請輸入姓名或公司名稱" />
              </div>
              <div class="form-group">
                <label>統一編號</label>
                <input type="text" v-model="form.tax_id" />
              </div>
            </div>

            <div class="grid-cols-2">
              <div class="form-group">
                <label>聯絡電話 (市話/手機)</label>
                <input type="text" v-model="form.phone" placeholder="0912-345-678" />
              </div>
              <div class="form-group">
                <label>Email</label>
                <input type="email" v-model="form.email" />
              </div>
            </div>

            <div class="form-group">
              <label>收貨地址 (如：全家便利商店、住家)</label>
              <input type="text" v-model="form.delivery_address" placeholder="預設收件地址..." />
            </div>
            <div class="form-group">
              <div style="display:flex; justify-content:space-between; align-items:center;">
                <label style="margin-bottom:0;">帳單/發票地址</label>
                <button type="button" class="btn-link" @click="form.invoice_address = form.delivery_address" style="font-size:0.75rem;">同收貨地址</button>
              </div>
              <input type="text" v-model="form.invoice_address" style="margin-top:0.3rem;" placeholder="請款或寄發票地址..." />
            </div>
          </div>

          <!-- 帳款與對帳邏輯 -->
          <div style="border-bottom: 1px solid var(--border-glass); padding-bottom: 1rem; margin-bottom: 1rem;">
            <h4 style="color: var(--primary-color); margin-top: 0; margin-bottom: 0.8rem;">通路與對帳設定</h4>
            <div class="grid-cols-2">
              <div class="form-group">
                <label>隸屬通路</label>
                <select v-model="form.channel_id">
                  <option value="">無 (自行經營)</option>
                  <option v-for="ch in channels" :key="ch.id" :value="ch.id">{{ ch.name }}</option>
                </select>
              </div>
              <div class="form-group">
                <label>預設付款方式</label>
                <select v-model="form.payment_method">
                  <option value="信用卡">信用卡</option>
                  <option value="收現/貨到付款">收現 / 貨到付款</option>
                  <option value="銀行轉帳">銀行轉帳</option>
                  <option value="月結">月結 (B2B)</option>
                </select>
              </div>
            </div>
            
            <div class="grid-cols-2">
              <div class="form-group">
                <label>請款對象 (用於對帳)</label>
                <input type="text" v-model="form.billing_target" placeholder="如：蝦皮拍賣、藍新金流..." />
              </div>
              <div class="form-group">
                <label>業務/聯絡窗口</label>
                <input type="text" v-model="form.contact_person" />
              </div>
            </div>
          </div>

          <!-- 統一備註 -->
          <div class="form-group" style="margin-bottom: 0;">
            <label>內部備註</label>
            <textarea v-model="form.note" rows="2" placeholder="其他次要資訊記錄於此..."></textarea>
          </div>

        </div>
        <div class="modal-actions" style="margin-top: 1.5rem;">
          <button class="btn btn-secondary" @click="closeForm">取消</button>
          <button class="btn btn-primary" @click="saveCustomer">{{ isEditing ? '儲存變更' : '新增會員' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Customers',
  data() {
    return {
      customers: [],
      channels: [],
      tiers: [],
      searchQuery: '',
      filterType: '',
      showForm: false,
      isEditing: false,
      form: this.getEmptyForm(),
      activeTab: 'basic'
    }
  },
  computed: {
    filteredCustomers() {
      let result = this.customers
      if (this.filterType) {
        result = result.filter(c => c.type === this.filterType)
      }
      if (this.searchQuery.trim()) {
        const q = this.searchQuery.toLowerCase()
        result = result.filter(c =>
          (c.code && c.code.toLowerCase().includes(q)) ||
          (c.name && c.name.toLowerCase().includes(q)) ||
          (c.phone && c.phone.includes(q)) ||
          (c.mobile && c.mobile.includes(q)) ||
          (c.email && c.email.toLowerCase().includes(q))
        )
      }
      return result
    }
  },
  mounted() {
    if (this.$route.query.type) {
      this.filterType = this.$route.query.type
    }
    this.fetchCustomers()
    this.fetchChannels()
    this.fetchTiers()
  },
  watch: {
    '$route.query.type'(newType) {
      if (newType) {
        this.filterType = newType
      }
    },
    'form.type'() {
      // 當類型改變且是非編輯狀態時，自動重新產生代號
      if (!this.isEditing && this.showForm) {
        this.generateCode()
      }
    }
  },
  methods: {
    getEmptyForm() {
      return {
        tenant_id: 1,
        code: '',
        name: '',
        type: 'RETAIL',
        phone: '',
        email: '',
        delivery_address: '',
        invoice_address: '',
        tax_id: '',
        channel_id: null,
        payment_method: '信用卡',
        billing_target: '',
        contact_person: '',
        note: ''
      }
    },
    async fetchCustomers() {
      try {
        const res = await this.$api.get('/customers/')
        this.customers = res.data
      } catch (err) {
        console.error('Failed to load customers:', err)
      }
    },
    async fetchChannels() {
      try {
        const res = await this.$api.get('/channels/')
        this.channels = res.data
      } catch (err) {
        console.error('Failed to load channels:', err)
      }
    },
    async fetchTiers() {
      try {
        const res = await this.$api.get('/member-tiers/')
        this.tiers = res.data
      } catch (err) {
        console.error('Failed to load member tiers:', err)
      }
    },
    getChannelName(channelId) {
      if (!channelId) return '-'
      const ch = this.channels.find(c => c.id === channelId)
      return ch ? ch.name : '-'
    },
    getTierName(tierId) {
      if (!tierId) return '-'
      const t = this.tiers.find(t => t.id === tierId)
      return t ? t.name : '-'
    },
    typeLabel(type) {
      const map = { RETAIL: '一般會員', AGENT: '代理商', CHANNEL: '通路商' }
      return map[type] || type
    },
    typeBadgeClass(type) {
      const map = { RETAIL: 'badge-info', AGENT: 'badge-warning', CHANNEL: 'badge-success' }
      return map[type] || 'badge-info'
    },
    onTypeChanged() {
      // 觸發自動取號
      if (!this.isEditing) {
        this.generateCode()
      }
    },
    generateCode() {
      // 根據類型自動產生 C 或 T 開頭的下一個號碼
      const prefix = this.form.type === 'RETAIL' ? 'C' : 'T'
      const samePrefix = this.customers.filter(c => c.code && c.code.startsWith(prefix))
      let maxNum = 0
      for (const c of samePrefix) {
        const num = parseInt(c.code.slice(1) || '0')
        if (num > maxNum) maxNum = num
      }
      this.form.code = prefix + String(maxNum + 1).padStart(5, '0')
    },
    openCustomerForm(customer) {
      if (customer) {
        this.isEditing = true
        this.form = { ...this.getEmptyForm(), ...customer }
      } else {
        this.isEditing = false
        this.form = this.getEmptyForm()
        // 自動取號（根據類型 C 或 T 開頭）
        this.generateCode()
      }
      this.showForm = true
    },
    closeForm() {
      this.showForm = false
    },
    async saveCustomer() {
      if (!this.form.code || !this.form.name) {
        alert('請填寫代號和姓名')
        return
      }
      const url = this.isEditing
        ? `/customers/${this.form.id}`
        : '/customers/'
      const method = this.isEditing ? 'put' : 'post'
      try {
        const res = await this.$api[method](url, this.form)
        alert(this.isEditing ? '更新成功！' : '新增成功！')
        this.closeForm()
        this.fetchCustomers()
      } catch (err) {
        alert('儲存失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async deleteCustomer(customer) {
      if (!confirm(`確定要刪除會員 ${customer.name} (${customer.code})？`)) return
      try {
        await this.$api.delete(`/customers/${customer.id}`)
        alert('刪除成功')
        this.fetchCustomers()
      } catch (err) {
        alert('刪除失敗: ' + (err.response?.data?.detail || err.message))
      }
    }
  }
}
</script>

<style scoped>
.btn-link {
  background: none;
  border: none;
  color: var(--color-primary);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  padding: 0;
}
.btn-link:hover {
  text-decoration: underline;
}
.customer-code {
  font-weight: 600;
  color: var(--color-primary);
}
.badge-info { background: rgba(99, 102, 241, 0.2); color: #a78bfa; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; }
.badge-warning { background: rgba(245, 158, 11, 0.2); color: #f59e0b; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; }
.badge-success { background: rgba(16, 185, 129, 0.2); color: #10b981; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; }
.tier-badge { background: rgba(234,179,8,0.15); color: #eab308; padding: 0.15rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: 600; }
.text-muted { color: var(--text-muted); font-size: 0.85rem; }

.modal-backdrop {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.7);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-card { width: 90%; box-shadow: 0 20px 50px rgba(0,0,0,0.5); }
.modal-form { padding: 1rem 0; max-height: 65vh; overflow-y: auto; }
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  border-top: 1px solid var(--border-glass);
  padding-top: 1rem;
}
textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  background: var(--bg-input);
  color: var(--text-main);
  font-family: inherit;
  resize: vertical;
}


.tab-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}
.tab-btn.active {
  color: var(--primary-color);
  background: rgba(139, 105, 20, 0.1);
  font-weight: 600;
}
</style>
