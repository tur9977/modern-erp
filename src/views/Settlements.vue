<template>
  <div class="animate-fade-in">
    <h1>月底結帳單 (f_rs)</h1>
    <p class="subtitle">針對各個通路代理商窗口，批量勾選當月已出貨未結單據，一鍵生成應收帳款與 FIFO 銷貨成本總帳</p>

    <div class="grid-cols-2">
      <!-- Create Settlement Form -->
      <div class="glass-card">
        <h2>建立月底結帳單</h2>
        <form @submit.prevent="submitSettlement">
          <div class="form-group">
            <label>結帳單號</label>
            <input type="text" v-model="settlementNo" required placeholder="例如: SETTLE-202605" />
          </div>

          <div class="grid-cols-2" style="margin-bottom: 0;">
            <div class="form-group">
              <label>結帳月份</label>
              <input type="month" v-model="settleMonth" @change="loadUnsettledBills" />
            </div>
            <div class="form-group">
              <label style="display:flex; justify-content:space-between; align-items:center;">
                <span>請款渠道 (Channel)</span>
                <button type="button" class="btn-link" @click="openQuickAdd('channel')">+ 新增</button>
              </label>
              <select v-model="channelId" @change="loadUnsettledBills" required>
                <option value="" disabled>請選擇請款渠道</option>
                <option v-for="ch in channels" :key="ch.id" :value="ch.id">
                  {{ ch.name }} ({{ ch.code }})
                </option>
              </select>
            </div>
          </div>

          <div class="grid-cols-2" style="margin-bottom: 0;">
            <div class="form-group">
              <label style="display:flex; justify-content:space-between; align-items:center;">
                <span>收款方式</span>
                <button type="button" class="btn-link" @click="openQuickAdd('paymentMethod')">+ 新增</button>
              </label>
              <select v-model="paymentMethodId" required>
                <option value="" disabled>請選擇收款方式</option>
                <option v-for="pm in paymentMethods" :key="pm.id" :value="pm.id">
                  {{ pm.name }} ({{ pm.code }})
                </option>
              </select>
            </div>
            <div class="form-group">
              <label style="display:flex; justify-content:space-between; align-items:center;">
                <span>請款對象 (Target)</span>
                <button type="button" class="btn-link" @click="openQuickAdd('collectionTarget')">+ 新增</button>
              </label>
              <select v-model="collectionTargetId" required>
                <option value="" disabled>請選擇請款對象</option>
                <option v-for="ct in collectionTargets" :key="ct.id" :value="ct.id">
                  {{ ct.name }} ({{ ct.code }})
                </option>
              </select>
            </div>
          </div>

          <!-- Unsettled Shipments List -->
          <div style="border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem; margin-bottom: 1rem;">
            <h3 style="font-size: 0.95rem; margin-bottom: 0.8rem; color: var(--text-muted);">選擇待核銷託售單</h3>
            
            <div v-if="loadingBills" style="padding: 1.5rem; text-align: center; color: var(--text-muted);">
              正在加載待結單據...
            </div>
            <div v-else-if="unsettledBills.length === 0" style="padding: 1.5rem; text-align: center; color: var(--text-muted);">
              無待結帳的託售出貨單 (請確認該渠道是否有 SHIPPED 狀態的託售單)
            </div>

            <table v-else>
              <thead>
                <tr>
                  <th style="width: 40px;">選擇</th>
                  <th>單號</th>
                  <th>代理商</th>
                  <th>出貨日</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="bill in unsettledBills" :key="bill.id">
                  <td>
                    <input type="checkbox" :value="bill.id" v-model="selectedBillIds" style="width: auto; cursor:pointer;" />
                  </td>
                  <td>{{ bill.consignment_no }}</td>
                  <td>{{ bill.agent_name || '代理商' }}</td>
                  <td>{{ bill.ship_date }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Selected Totals -->
          <div style="display: flex; justify-content: space-between; align-items: center; background: rgba(255,255,255,0.03); padding: 1rem; border-radius: var(--radius-input); margin-bottom: 1.5rem;">
            <div>
              <div style="font-size: 0.8rem; color: var(--text-muted);">已勾選單數</div>
              <div style="font-size: 1rem; font-weight: 600;">{{ selectedBillIds.length }} 筆</div>
            </div>
            <div style="text-align: right;">
              <div style="font-size: 0.8rem; color: var(--text-muted);">結算進度</div>
              <div style="font-size: 1.2rem; font-weight: 700; color: var(--color-success);">勾選以進行一鍵結帳</div>
            </div>
          </div>

          <button type="submit" class="btn btn-primary" style="width: 100%;" :disabled="selectedBillIds.length === 0">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 0.5rem;"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
            確認結帳 (認列應收、結轉 COGS)
          </button>
        </form>

        <!-- Settlement Result Panel -->
        <div v-if="settlementResult" class="settlement-result">
          <div class="result-header">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            <h3>結帳完成</h3>
          </div>

          <div class="result-grid">
            <div class="result-item">
              <span class="result-label">結帳單號</span>
              <span class="result-value font-mono">{{ settlementResult.settlement_no }}</span>
            </div>
            <div class="result-item">
              <span class="result-label">結帳月份</span>
              <span class="result-value">{{ settlementResult.settle_month }}</span>
            </div>
            <div class="result-item highlight">
              <span class="result-label">應收帳款 (AR) 編號</span>
              <span class="result-value font-mono">{{ settlementResult.ar_no }}</span>
            </div>
          </div>

          <!-- GL Entries -->
          <div class="gl-entries">
            <div class="result-label">總帳分錄 (GL)</div>
            <div class="gl-row">
              <span class="gl-type">借項</span>
              <span class="gl-account">1120 應收帳款</span>
              <span class="gl-amount">${{ (settlementResult.total_amount || 0).toLocaleString() }}</span>
            </div>
            <div class="gl-row">
              <span class="gl-type">貸項</span>
              <span class="gl-account">4100 營業收入</span>
              <span class="gl-amount">${{ (settlementResult.total_amount || 0).toLocaleString() }}</span>
            </div>
            <div class="gl-row cogs">
              <span class="gl-type">借項</span>
              <span class="gl-account">5100 銷貨成本 (FIFO)</span>
              <span class="gl-amount">-</span>
            </div>
            <div class="gl-row cogs">
              <span class="gl-type">貸項</span>
              <span class="gl-account">1200 存貨</span>
              <span class="gl-amount">-</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Past Settlements List -->
      <div class="glass-card">
        <h2>月底結帳歷史紀錄</h2>
        <div style="max-height: 500px; overflow-y: auto;">
          <table>
            <thead>
              <tr>
                <th>單號</th>
                <th>月份</th>
                <th>請款對象</th>
                <th>總金額</th>
                <th>狀態</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="settle in settlementsHistory" :key="settle.id">
                <td>{{ settle.settlement_no }}</td>
                <td>{{ settle.settle_month }}</td>
                <td>{{ settle.collection_target?.name || '請款對象' }}</td>
                <td>${{ settle.total_amount }}</td>
                <td><span class="badge badge-success">已確認 (AR與總帳已生成)</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Quick Add Modal -->
    <div class="modal-backdrop" v-if="quickAddType">
      <div class="modal-card glass-card">
        <h3>快速新增 - {{ quickAddTitle }}</h3>
        <div class="modal-form">
          <div class="form-group">
            <label>代碼 / Code</label>
            <input type="text" v-model="quickAddForm.code" required placeholder="例如: MYCODE-01" />
          </div>
          <div class="form-group">
            <label>名稱 / Name</label>
            <input type="text" v-model="quickAddForm.name" required placeholder="例如: 官網大額支付" />
          </div>
          <div class="form-group" v-if="quickAddType === 'channel'">
            <label>類型 / Type</label>
            <select v-model="quickAddForm.type">
              <option value="direct">直營 (direct)</option>
              <option value="consignment">加盟託售 (consignment)</option>
            </select>
          </div>
          <div class="form-group" v-if="quickAddType === 'paymentMethod'">
            <label>付款類型</label>
            <select v-model="quickAddForm.type">
              <option value="CASH">現金</option>
              <option value="CARD">信用卡</option>
              <option value="TRANSFER">轉帳</option>
            </select>
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeQuickAdd">取消</button>
          <button class="btn btn-primary" @click="submitQuickAdd">保存並選擇</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'Settlements',
  data() {
    return {
      settlementNo: 'SETTLE-' + new Date().toISOString().slice(0, 7).replace('-', ''),
      settleMonth: new Date().toISOString().slice(0, 7),
      channelId: '',
      paymentMethodId: '',
      collectionTargetId: '',
      loadingBills: false,
      unsettledBills: [],
      selectedBillIds: [],
      settlementsHistory: [],

      // Master arrays
      channels: [],
      paymentMethods: [],
      collectionTargets: [],

      // Quick Add Modals
      quickAddType: null,
      quickAddForm: {
        code: '',
        name: '',
        type: 'direct'
      },

      // Settlement Result
      settlementResult: null
    }
  },
  computed: {
    quickAddTitle() {
      if (this.quickAddType === 'channel') return '銷售渠道'
      if (this.quickAddType === 'paymentMethod') return '付款方式'
      if (this.quickAddType === 'collectionTarget') return '請款對象'
      return ''
    }
  },
  mounted() {
    this.fetchMasterData()
    this.fetchSettlementsHistory()
  },
  methods: {
    async fetchMasterData() {
      try {
        const [resCh, resPm, resCt] = await Promise.all([
          supabase.from('erp_channels/'),
          supabase.from('erp_payment-methods/'),
          supabase.from('erp_collection-targets/')
        ])
        this.channels = resCh.data
        if (this.channels.length > 0) this.channelId = this.channels[0].id
        this.paymentMethods = resPm.data
        if (this.paymentMethods.length > 0) this.paymentMethodId = this.paymentMethods[0].id
        this.collectionTargets = resCt.data
        if (this.collectionTargets.length > 0) this.collectionTargetId = this.collectionTargets[0].id

        this.loadUnsettledBills()
      } catch (err) {
        console.error('Failed to load master data:', err)
      }
    },
    async fetchSettlementsHistory() {
      try {
        const res = await supabase.from('erp_settlements/')
        this.settlementsHistory = res.data
      } catch (err) {
        console.error('Failed to load settlements history:', err)
      }
    },
    async loadUnsettledBills() {
      if (!this.channelId) return
      this.loadingBills = true
      this.selectedBillIds = []
      try {
        const res = await supabase.from('erp_consignments/')
        const allCons = res.data
        this.unsettledBills = allCons.filter(c => c.channel_id === parseInt(this.channelId) && c.status === 'SHIPPED')
      } catch (err) {
        console.error('Failed to load unsettled bills:', err)
      } finally {
        this.loadingBills = false
      }
    },
    // Quick Add
    openQuickAdd(type) {
      this.quickAddType = type
      this.quickAddForm = {
        tenant_id: 1,
        code: '',
        name: '',
        type: type === 'channel' ? 'direct' : type === 'paymentMethod' ? 'CASH' : undefined
      }
    },
    closeQuickAdd() {
      this.quickAddType = null
    },
    async submitQuickAdd() {
      let endpoint = ''
      if (this.quickAddType === 'channel') endpoint = 'channels'
      if (this.quickAddType === 'paymentMethod') endpoint = 'payment-methods'
      if (this.quickAddType === 'collectionTarget') endpoint = 'collection-targets'

      try {
        const res = await this.$api.post(`/${endpoint}/`, this.quickAddForm)
        const data = res.data
        alert('快速新增成功！')
        await this.fetchMasterData()

        if (this.quickAddType === 'channel') this.channelId = data.id
        if (this.quickAddType === 'paymentMethod') this.paymentMethodId = data.id
        if (this.quickAddType === 'collectionTarget') this.collectionTargetId = data.id

        this.closeQuickAdd()
      } catch (err) {
        alert('新增失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async submitSettlement() {
      if (this.selectedBillIds.length === 0) return

      const payload = {
        tenant_id: 1,
        settlement_no: this.settlementNo,
        channel_id: parseInt(this.channelId),
        collection_target_id: parseInt(this.collectionTargetId),
        payment_method_id: parseInt(this.paymentMethodId),
        consignment_ids: this.selectedBillIds.map(id => parseInt(id)),
        settle_month: this.settleMonth
      }

      try {
        const res = await supabase.from('erp_settlements/', payload)
        this.settlementResult = {
          settlement_id: res.data.settlement_id,
          ar_no: res.data.ar_no,
          settlement_no: this.settlementNo,
          settle_month: this.settleMonth,
          total_amount: this.selectedBillIds.length * 1000, // approximate
          commissions: res.data.commissions || []
        }
        this.settlementNo = 'SETTLE-' + new Date().toISOString().slice(0, 7).replace('-', '') + '-' + Math.floor(Math.random() * 1000)
        this.selectedBillIds = []
        this.loadUnsettledBills()
        this.fetchSettlementsHistory()
      } catch (err) {
        alert('核銷失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
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

.font-mono { font-family: 'SF Mono', 'Fira Code', monospace; }

/* Settlement Result Panel */
.settlement-result {
  margin-top: 1.5rem;
  background: rgba(34,197,94,0.06);
  border: 1px solid rgba(34,197,94,0.2);
  border-radius: var(--radius-card);
  padding: 1.25rem;
}
.result-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}
.result-header h3 { color: #22c55e; font-size: 1.1rem; margin: 0; }
.result-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
  margin-bottom: 1rem;
}
.result-item { display: flex; flex-direction: column; gap: 0.2rem; }
.result-item.highlight { grid-column: 1 / -1; background: rgba(34,197,94,0.1); padding: 0.75rem; border-radius: 0.5rem; }
.result-label { font-size: 0.75rem; color: var(--text-muted); }
.result-value { font-size: 0.95rem; font-weight: 600; color: var(--text-primary); }

.gl-entries { margin-top: 1rem; padding-top: 1rem; border-top: 1px solid rgba(34,197,94,0.2); }
.gl-row {
  display: grid;
  grid-template-columns: 60px 1fr auto;
  gap: 0.5rem;
  padding: 0.4rem 0;
  font-size: 0.85rem;
  align-items: center;
}
.gl-row.cogs { opacity: 0.6; }
.gl-type { font-size: 0.7rem; font-weight: 600; text-transform: uppercase; color: var(--text-muted); }
.gl-account { color: var(--text-secondary); }
.gl-amount { font-weight: 600; font-family: 'SF Mono', 'Fira Code', monospace; }

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
