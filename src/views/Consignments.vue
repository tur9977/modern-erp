<template>
  <div class="animate-fade-in">
    <h1>託售出貨單 (clm_cust)</h1>
    <p class="subtitle">將商品分撥至各合作經銷/加盟代理商通路。叫貨與確認出貨時會自動觸發「風控攔截器」</p>

    <!-- Risk Alert Banner -->
    <div v-if="riskResult" class="glass-card animate-fade-in" :style="riskAlertStyle">
      <h3 style="display:flex; align-items:center; gap:0.5rem; margin-bottom: 0.5rem;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
        風控攔截報告：{{ riskResult.status }}
      </h3>
      <p>{{ riskResult.message }}</p>
    </div>

    <div class="grid-cols-2">
      <!-- Create Consignment Form -->
      <div class="glass-card">
        <h2>建立託售叫貨單</h2>
        <form @submit.prevent="submitConsignment">
          <div class="form-group">
            <label>託售單號</label>
            <input type="text" v-model="consignmentNo" required placeholder="例如: CLM-20260531001" />
          </div>

          <div class="grid-cols-2" style="margin-bottom: 0;">
            <div class="form-group">
              <label style="display:flex; justify-content:space-between; align-items:center;">
                <span>選擇加盟商 (Agent)</span>
                <button type="button" class="btn-link" @click="openQuickAddAgent">+ 新增</button>
              </label>
              <select v-model="agentId" @change="evaluateRisk" required>
                <option value="" disabled>請選擇加盟商</option>
                <option v-for="agent in agents" :key="agent.id" :value="agent.id">
                  {{ agent.name }} ({{ agent.code }}) {{ agent.contact_phone ? '- ' + agent.contact_phone : '' }}
                </option>
              </select>
            </div>
            <div class="form-group">
              <label>出貨日期</label>
              <input type="date" v-model="shipDate" />
            </div>
          </div>

          <div class="grid-cols-2" style="margin-bottom: 0;">
            <div class="form-group">
              <label>分撥渠道 (Channel)</label>
              <select v-model="channelId" required>
                <option value="" disabled>請選擇分撥渠道</option>
                <option v-for="ch in channels" :key="ch.id" :value="ch.id">
                  {{ ch.name }} ({{ ch.code }})
                </option>
              </select>
            </div>
            <div class="form-group">
              <label>付款方式</label>
              <select v-model="paymentMethodId" required>
                <option value="" disabled>請選擇付款方式</option>
                <option v-for="pm in paymentMethods" :key="pm.id" :value="pm.id">
                  {{ pm.name }} ({{ pm.code }})
                </option>
              </select>
            </div>
          </div>

          <div class="form-group">
            <label>請款對象</label>
            <select v-model="collectionTargetId" required>
              <option value="" disabled>請選擇請款對象</option>
              <option v-for="ct in collectionTargets" :key="ct.id" :value="ct.id">
                {{ ct.name }} ({{ ct.code }})
              </option>
            </select>
          </div>

          <div style="border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem; margin-bottom: 1rem;">
            <h3 style="font-size: 0.95rem; margin-bottom: 0.8rem; color: var(--text-muted);">出貨商品明細</h3>
            
            <div style="display: grid; grid-template-columns: 2fr 1fr 1.2fr; gap: 1rem; margin-bottom: 1rem; align-items: flex-end;">
              <!-- 貨號速查 Auto-Suggest -->
              <div class="form-group" style="margin-bottom: 0; position: relative;">
                <label>選擇商品 (貨號速查)</label>
                <input 
                  type="text" 
                  v-model="itemSearchQuery" 
                  placeholder="輸入貨號或品名 (例如: D051)..." 
                  @input="onItemSearchInput"
                  @focus="showItemSuggestions = true"
                  ref="searchInput"
                />
                <!-- Auto-suggest suggestions box -->
                <ul v-if="showItemSuggestions && filteredItems.length > 0" class="suggestions-dropdown">
                  <li v-for="item in filteredItems" :key="item.id" @click="selectSearchItem(item)">
                    <span class="sku-highlight">{{ item.sku }}</span> - {{ item.name }} 
                    <span class="spec-text">({{ item.color || '無色' }}/{{ item.size || '無尺寸' }})</span> 
                    <span class="price-badge">${{ item.retail_price }}</span>
                  </li>
                </ul>
              </div>
              <div class="form-group" style="margin-bottom: 0;">
                <label>出貨數量</label>
                <input type="number" v-model="qty" min="1" @input="evaluateRisk" />
              </div>
              <button type="button" class="btn btn-secondary" @click="addItem">加入明細</button>
            </div>

            <div v-if="selectedItemInfo" class="selected-item-preview animate-fade-in">
              已選擇: <strong>[{{ selectedItemInfo.sku }}] {{ selectedItemInfo.name }}</strong> | 
              規格: 顏色: {{ selectedItemInfo.color || '無' }}, 尺寸: {{ selectedItemInfo.size || '無' }} | 
              單價: <span class="price-highlight">${{ selectedItemInfo.retail_price }}</span>
            </div>

            <!-- Item Table -->
            <table v-if="itemsList.length > 0">
              <thead>
                <tr>
                  <th>商品</th>
                  <th>規格</th>
                  <th>數量</th>
                  <th>合約單價</th>
                  <th>總計</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(item, index) in itemsList" :key="index">
                  <td>{{ item.name }} ({{ item.sku }})</td>
                  <td>{{ item.color || '-' }} / {{ item.size || '-' }}</td>
                  <td>{{ item.qty }} 件</td>
                  <td>${{ item.price }}</td>
                  <td>${{ item.qty * item.price }}</td>
                  <td>
                    <button type="button" @click="removeItem(index)" style="background:none; border:none; color: var(--color-danger); cursor:pointer;">刪除</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div style="display:flex; gap: 1rem;">
            <button type="button" class="btn btn-secondary" style="flex:1;" @click="evaluateRisk">風控試算</button>
            <button type="submit" class="btn btn-primary" style="flex:2;" :disabled="riskResult && riskResult.status === 'BLOCKED'">
              確認叫貨與出庫 (SHIP)
            </button>
          </div>
        </form>
      </div>

      <!-- Past Consignments List -->
      <div class="glass-card">
        <h2>託售出貨歷史紀錄</h2>
        <div style="max-height: 500px; overflow-y: auto;">
          <table>
            <thead>
              <tr>
                <th>單號</th>
                <th>加盟商</th>
                <th>出貨日</th>
                <th>狀態</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="con in consignmentsHistory" :key="con.id">
                <td>{{ con.consignment_no }}</td>
                <td>{{ con.agent?.name || '未知加盟商' }}</td>
                <td>{{ con.ship_date }}</td>
                <td>
                  <span v-if="con.status === 'SETTLED'" class="badge badge-success">已月底結帳</span>
                  <span v-else-if="con.status === 'SHIPPED'" class="badge badge-warning">已出貨未結</span>
                  <span v-else class="badge badge-muted">已出庫</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Quick Add Customer/Agent Modal -->
    <div class="modal-backdrop" v-if="showQuickAddAgentModal">
      <div class="modal-card glass-card">
        <h3>快速新增 - 加盟託售代理商 (CRM)</h3>
        <div class="modal-form">
          <div class="form-group">
            <label>代理商代碼 (如: T005)</label>
            <input type="text" v-model="agentForm.code" required placeholder="例如: T005" />
          </div>
          <div class="form-group">
            <label>公司/代理商名稱</label>
            <input type="text" v-model="agentForm.name" required placeholder="例如: 雙子星網路商行" />
          </div>
          <div class="form-group">
            <label>聯絡電話 (CRM 資料)</label>
            <input type="text" v-model="agentForm.contact_phone" placeholder="例如: 02-23456789" />
          </div>
          <div class="form-group">
            <label>聯絡人</label>
            <input type="text" v-model="agentForm.contact_person" placeholder="例如: 林經理" />
          </div>
          <div class="form-group">
            <label>送貨地址</label>
            <input type="text" v-model="agentForm.address" placeholder="例如: 台北市中山區..." />
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeQuickAddAgent">取消</button>
          <button class="btn btn-primary" @click="submitQuickAddAgent">保存並選擇</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'Consignments',
  data() {
    return {
      consignmentNo: 'CLM-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '001',
      agentId: '',
      channelId: '',
      paymentMethodId: '',
      collectionTargetId: '',
      shipDate: new Date().toISOString().slice(0, 10),
      
      // Auto-suggest product search
      itemSearchQuery: '',
      showItemSuggestions: false,
      filteredItems: [],
      selectedItemInfo: null,
      qty: 1,

      itemsList: [],
      consignmentsHistory: [],
      riskResult: null,

      // Master arrays
      agents: [],
      channels: [],
      paymentMethods: [],
      collectionTargets: [],
      items: [],

      // Quick Add Agent Modal
      showQuickAddAgentModal: false,
      agentForm: {
        code: '',
        name: '',
        contact_phone: '',
        contact_person: '',
        address: ''
      }
    }
  },
  computed: {
    riskAlertStyle() {
      if (!this.riskResult) return {}
      if (this.riskResult.status === 'BLOCKED') {
        return {
          background: 'rgba(239, 68, 68, 0.15)',
          borderColor: 'var(--color-danger)',
          color: '#fff',
          marginBottom: '1.5rem'
        }
      }
      return {
        background: 'rgba(245, 158, 11, 0.15)',
        borderColor: 'var(--color-warning)',
        color: '#fff',
        marginBottom: '1.5rem'
      }
    }
  },
  mounted() {
    this.fetchMasterData()
    this.fetchConsignmentsHistory()
    document.addEventListener('click', this.handleClickOutside)
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleClickOutside)
  },
  methods: {
    async fetchMasterData() {
      try {
        const [resAg, resCh, resPm, resCt, resIt] = await Promise.all([
          supabase.from('erp_customers/'),
          supabase.from('erp_channels/'),
          supabase.from('erp_payment-methods/'),
          supabase.from('erp_collection-targets/'),
          supabase.from('erp_items/')
        ])
        const allCusts = resAg.data
        this.agents = allCusts.filter(c => c.type === 'AGENT' || c.code.startsWith('T'))
        if (this.agents.length > 0) this.agentId = this.agents[0].id
        this.channels = resCh.data
        if (this.channels.length > 0) this.channelId = this.channels[0].id
        this.paymentMethods = resPm.data
        if (this.paymentMethods.length > 0) this.paymentMethodId = this.paymentMethods[0].id
        this.collectionTargets = resCt.data
        if (this.collectionTargets.length > 0) this.collectionTargetId = this.collectionTargets[0].id
        this.items = resIt.data
      } catch (err) {
        console.error('Failed to load master data:', err)
      }
    },
    async fetchConsignmentsHistory() {
      try {
        const res = await supabase.from('erp_consignments/')
        this.consignmentsHistory = res.data
      } catch (err) {
        console.error('Failed to load consignments history:', err)
      }
    },
    onItemSearchInput() {
      if (!this.itemSearchQuery.trim()) {
        this.filteredItems = []
        return
      }
      const q = this.itemSearchQuery.toLowerCase()
      this.filteredItems = this.items.filter(item => 
        (item.sku && item.sku.toLowerCase().includes(q)) || 
        (item.name && item.name.toLowerCase().includes(q))
      ).slice(0, 50)
    },
    selectSearchItem(item) {
      this.selectedItemInfo = item
      this.itemSearchQuery = item.sku
      this.showItemSuggestions = false
      this.filteredItems = []
    },
    handleClickOutside(e) {
      if (this.$refs.searchInput && !this.$refs.searchInput.contains(e.target)) {
        this.showItemSuggestions = false
      }
    },
    addItem() {
      if (!this.selectedItemInfo) {
        alert('請先搜尋並選擇一個商品')
        return
      }
      const matched = this.selectedItemInfo
      const existing = this.itemsList.find(i => i.item_id === matched.id)
      if (existing) {
        existing.qty += this.qty
      } else {
        this.itemsList.push({
          item_id: matched.id,
          sku: matched.sku,
          name: matched.name,
          color: matched.color,
          size: matched.size,
          qty: this.qty,
          price: matched.retail_price
        })
      }
      this.itemSearchQuery = ''
      this.selectedItemInfo = null
      this.evaluateRisk()
    },
    removeItem(index) {
      this.itemsList.splice(index, 1)
      this.evaluateRisk()
    },
    // Quick Add Agent (Customer CRM)
    openQuickAddAgent() {
      this.showQuickAddAgentModal = true
      this.agentForm = {
        tenant_id: 1,
        code: '',
        name: '',
        type: 'AGENT',
        contact_phone: '',
        contact_person: '',
        address: '',
        is_active: true
      }
    },
    closeQuickAddAgent() {
      this.showQuickAddAgentModal = false
    },
    async submitQuickAddAgent() {
      try {
        const res = await supabase.from('erp_customers/', this.agentForm)
        const data = res.data
        alert('快速新增代理商成功！')
        await this.fetchMasterData()
        this.agentId = data.id
        this.closeQuickAddAgent()
      } catch (err) {
        alert('新增失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async evaluateRisk() {
      if (!this.agentId || this.itemsList.length === 0) return
      try {
        const res = await supabase.from('erp_consignments/risk-evaluate', {
          tenant_id: 1,
          consignment_no: this.consignmentNo,
          channel_id: parseInt(this.channelId),
          collection_target_id: parseInt(this.collectionTargetId),
          payment_method_id: parseInt(this.paymentMethodId),
          agent_id: parseInt(this.agentId),
          ship_date: this.shipDate,
          items: this.itemsList.map(item => ({
            item_id: item.item_id,
            qty: parseFloat(item.qty),
            agreed_price: parseFloat(item.price)
          }))
        })
        const result = res.data
        if (result.status === 'PASS') {
          this.riskResult = { status: '通過 (PASS)', message: '風控評級良好，未結帳在庫與營運天數皆在安全邊際內。' }
        } else {
          this.riskResult = { status: result.status, message: result.message }
        }
      } catch (err) {
        this.riskResult = { status: 'BLOCKED', message: err.response?.data?.detail || err.message }
      }
    },
    async submitConsignment() {
      if (this.itemsList.length === 0) {
        alert('請加入出貨明細')
        return
      }
      try {
        const res = await supabase.from('erp_consignments/', {
          tenant_id: 1,
          consignment_no: this.consignmentNo,
          channel_id: parseInt(this.channelId),
          collection_target_id: parseInt(this.collectionTargetId),
          payment_method_id: parseInt(this.paymentMethodId),
          agent_id: parseInt(this.agentId),
          ship_date: this.shipDate,
          items: this.itemsList.map(item => ({
            item_id: item.item_id,
            qty: parseFloat(item.qty),
            agreed_price: parseFloat(item.price)
          }))
        })
        const result = res.data
        const shipRes = await this.$api.post(`/consignments/${result.consignment_id}/ship`)
        if (shipRes.data.status === 'ok' || shipRes.status === 200) {
          alert('託售出庫確認成功！已轉移實體庫存至加盟商託售在庫。')
          this.itemsList = []
          this.consignmentNo = 'CLM-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + Math.floor(Math.random() * 1000)
          this.riskResult = null
          this.fetchConsignmentsHistory()
        } else {
          alert('託售單建立成功，但出庫確認失敗')
        }
      } catch (err) {
        alert('發送請求失敗: ' + (err.response?.data?.detail || err.message))
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

/* Auto-Suggest Dropdown Box */
.suggestions-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: var(--bg-sidebar);
  border: 1px solid var(--border-glass);
  border-radius: 8px;
  max-height: 250px;
  overflow-y: auto;
  z-index: 100;
  list-style: none;
  padding: 0.5rem 0;
  box-shadow: var(--shadow-card);
}
.suggestions-dropdown li {
  padding: 0.6rem 1rem;
  cursor: pointer;
  font-size: 0.9rem;
  color: var(--text-main);
  border-bottom: 1px solid rgba(255,255,255,0.02);
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.suggestions-dropdown li:hover {
  background: var(--color-primary);
  color: #fff;
}
.sku-highlight {
  font-weight: 700;
  color: #a78bfa;
}
.suggestions-dropdown li:hover .sku-highlight {
  color: #fff;
}
.spec-text {
  color: var(--text-muted);
  font-size: 0.8rem;
  margin-left: 0.5rem;
}
.suggestions-dropdown li:hover .spec-text {
  color: rgba(255,255,255,0.8);
}
.price-badge {
  background: rgba(255,255,255,0.1);
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
  font-size: 0.8rem;
}

.selected-item-preview {
  background: rgba(99, 102, 241, 0.1);
  border: 1px solid rgba(99, 102, 241, 0.3);
  padding: 0.75rem 1rem;
  border-radius: 8px;
  margin-bottom: 1rem;
  font-size: 0.9rem;
}
.price-highlight {
  font-weight: 700;
  color: var(--color-primary);
}

/* Modals styling */
.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-card {
  width: 90%;
  max-width: 450px;
  box-shadow: 0 20px 50px rgba(0,0,0,0.5);
}
.modal-form {
  padding: 1rem 0;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  border-top: 1px solid var(--border-glass);
  padding-top: 1rem;
}
</style>
