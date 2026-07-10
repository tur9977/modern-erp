<template>
  <div class="page-container animate-fade-in">
    <div class="page-header">
      <h1>🛍️ 採購管理系統</h1>
      <p class="subtitle">採購訂單管理與進貨驗收流程</p>
    </div>

    <!-- Action Bar -->
    <div class="glass-card" style="margin-bottom: 1.5rem;">
      <div class="action-bar">
        <div class="filter-group">
          <select v-model="filterStatus" @change="fetchPurchaseOrders" class="filter-select">
            <option value="">全部狀態</option>
            <option value="PENDING">待收貨</option>
            <option value="PARTIALLY_RECEIVED">部分收貨</option>
            <option value="RECEIVED">已完成</option>
            <option value="CANCELLED">已取消</option>
          </select>
        </div>
        <div class="action-group">
          <button class="btn btn-outline" @click="openCreateDialog">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" y2="19"/><line x1="19" y1="12" y2="5"/></svg>
            新建採購單
          </button>
          <button class="btn btn-primary" @click="fetchPurchaseOrders">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/></svg>
            刷新
          </button>
        </div>
      </div>
    </div>

    <!-- Purchase Orders Table -->
    <div class="glass-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>PO 單號</th>
            <th>廠商</th>
            <th>訂購日期</th>
            <th>預計到貨</th>
            <th>總金額</th>
            <th>狀態</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="7" class="text-center text-muted" style="padding: 2rem;">載入中...</td>
          </tr>
          <tr v-else-if="purchaseOrders.length === 0">
            <td colspan="7" class="text-center text-muted" style="padding: 2rem;">尚無採購單資料</td>
          </tr>
          <tr v-else v-for="po in purchaseOrders" :key="po.id">
            <td class="font-mono">{{ po.po_no }}</td>
            <td>{{ po.vendor_id }}</td>
            <td>{{ po.order_date }}</td>
            <td>{{ po.expected_date || '-' }}</td>
            <td>${{ po.total }}</td>
            <td><span :class="statusBadge(po.status)">{{ statusLabel(po.status) }}</span></td>
            <td>
              <button
                v-if="po.status === 'PENDING' || po.status === 'PARTIALLY_RECEIVED'"
                class="btn btn-sm btn-success"
                @click="openReceiveDialog(po)"
              >
                驗收進貨
              </button>
              <span v-else class="text-muted">-</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Receive Dialog -->
    <div class="modal-backdrop" v-if="showReceiveDialog">
      <div class="modal-card glass-card">
        <h3>進貨驗收</h3>
        <div v-if="selectedPO" class="receive-dialog-content">
          <div class="dialog-info">
            <div class="info-row">
              <span class="info-label">PO 單號</span>
              <span class="info-value font-mono">{{ selectedPO.po_no }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">廠商</span>
              <span class="info-value">{{ selectedPO.vendor_id }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">總金額</span>
              <span class="info-value">${{ selectedPO.total }}</span>
            </div>
          </div>

          <!-- PO Line Items -->
          <div class="line-items-section">
            <h4>採購明細</h4>
            <table class="mini-table">
              <thead>
                <tr>
                  <th>商品</th>
                  <th>訂購數量</th>
                  <th>已收數量</th>
                  <th>本次驗收</th>
                  <th>批次號</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in poItems" :key="item.id">
                  <td>{{ item.item_id }}</td>
                  <td>{{ item.qty }}</td>
                  <td>{{ item.received_qty || 0 }}</td>
                  <td>
                    <input
                      type="number"
                      :max="parseFloat(item.qty) - parseFloat(item.received_qty || 0)"
                      min="0"
                      step="1"
                      v-model.number="receiveItems[item.item_id].receive_qty"
                      class="qty-input"
                    />
                  </td>
                  <td>
                    <input
                      type="text"
                      v-model="receiveItems[item.item_id].lot_no"
                      placeholder="批次號"
                      class="lot-input"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="form-group">
            <label>入庫倉庫 <span class="required">*</span></label>
            <select v-model="receiveForm.warehouse_id" required>
              <option value="" disabled>請選擇倉庫</option>
              <option v-for="wh in warehouses" :key="wh.id" :value="wh.id">
                {{ wh.name || '倉庫 ' + wh.id }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>進貨日期</label>
            <input type="date" v-model="receiveForm.received_date" />
          </div>
        </div>

        <!-- Result Panel -->
        <div v-if="receiveResult" class="result-panel">
          <h4>進貨驗收結果</h4>
          <div class="result-message">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            <span>進貨已完成，狀態更新為 <strong>{{ receiveResult.po_status }}</strong></span>
          </div>
          <div class="lots-summary">
            <div class="result-label">入庫批次</div>
            <div v-for="lot in receiveResult.received_lots" :key="lot.lot_id" class="lot-row">
              <span>料號 {{ lot.item_id }}</span>
              <span>數量 {{ lot.qty }}</span>
              <span>批次 ID: {{ lot.lot_id }}</span>
            </div>
          </div>
        </div>

        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeReceiveDialog">取消</button>
          <button
            class="btn btn-success"
            @click="submitReceive"
            :disabled="!receiveForm.warehouse_id || receiving"
          >
            {{ receiving ? '處理中...' : '確認驗收入庫' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Create PO Dialog -->
    <div class="modal-backdrop" v-if="showCreateDialog">
      <div class="modal-card glass-card">
        <h3>新建採購單</h3>
        <div class="create-dialog-content">
          <div class="form-row">
            <div class="form-group">
              <label>PO 單號 <span class="required">*</span></label>
              <input type="text" v-model="createForm.po_no" required placeholder="例如: PO-20250608-001" />
            </div>
            <div class="form-group">
              <label>廠商 <span class="required">*</span></label>
              <select v-model="createForm.vendor_id" required>
                <option value="" disabled>請選擇廠商</option>
                <option v-for="v in vendors" :key="v.id" :value="v.id">
                  {{ v.name || v.code || '廠商 ' + v.id }}
                </option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>訂購日期 <span class="required">*</span></label>
              <input type="date" v-model="createForm.order_date" required />
            </div>
            <div class="form-group">
              <label>預計到貨日</label>
              <input type="date" v-model="createForm.expected_date" />
            </div>
          </div>

          <!-- Line Items -->
          <div class="line-items-section">
            <div class="line-items-header">
              <h4>採購明細</h4>
              <button type="button" class="btn btn-sm btn-outline" @click="addLineItem">+ 新增品項</button>
            </div>
            <table class="mini-table">
              <thead>
                <tr>
                  <th>商品 (item_id)</th>
                  <th>數量</th>
                  <th>單價</th>
                  <th>小計</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(item, idx) in createForm.items" :key="idx">
                  <td>
                    <input type="number" v-model.number="item.item_id" min="1" placeholder="ID" class="item-id-input" />
                  </td>
                  <td>
                    <input type="number" v-model.number="item.qty" min="1" step="1" class="qty-input" />
                  </td>
                  <td>
                    <input type="number" v-model.number="item.unit_price" min="0" step="0.01" class="price-input" />
                  </td>
                  <td class="subtotal">${{ (item.qty * item.unit_price || 0).toFixed(2) }}</td>
                  <td>
                    <button type="button" class="btn-icon" @click="removeLineItem(idx)" v-if="createForm.items.length > 1">✕</button>
                  </td>
                </tr>
              </tbody>
              <tfoot>
                <tr>
                  <td colspan="3" class="total-label">合計（含稅 5%）</td>
                  <td class="total-value">${{ createFormTotal.toFixed(2) }}</td>
                  <td></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeCreateDialog">取消</button>
          <button
            class="btn btn-primary"
            @click="submitCreatePO"
            :disabled="creatingPO || !createForm.po_no || !createForm.vendor_id || createForm.items.length === 0"
          >
            {{ creatingPO ? '建立中...' : '建立採購單' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'PurchaseOrders',
  data() {
    return {
      purchaseOrders: [],
      loading: false,
      filterStatus: '',
      showReceiveDialog: false,
      selectedPO: null,
      poItems: [],
      receiving: false,
      warehouses: [
        { id: 1, name: '總公司倉庫' },
        { id: 2, name: '門市倉庫 A' },
        { id: 3, name: '門市倉庫 B' }
      ],
      receiveForm: {
        warehouse_id: 1,
        received_date: new Date().toISOString().slice(0, 10)
      },
      receiveItems: {},
      receiveResult: null,

      // Create PO
      showCreateDialog: false,
      creatingPO: false,
      vendors: [],
      createForm: {
        po_no: 'PO-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-001',
        vendor_id: '',
        order_date: new Date().toISOString().slice(0, 10),
        expected_date: '',
        items: [{ item_id: null, qty: 1, unit_price: 0 }]
      }
    }
  },
  computed: {
    createFormTotal() {
      const subtotal = this.createForm.items.reduce((sum, item) => {
        return sum + (item.qty || 0) * (item.unit_price || 0)
      }, 0)
      return subtotal * 1.05 // tax
    }
  },
  mounted() {
    this.fetchPurchaseOrders()
    this.fetchVendors()
  },
  methods: {
    async fetchVendors() {
      try {
        const res = await supabase.from('erp_vendors/', { params: { tenant_id: 1 } })
        this.vendors = res.data
        if (this.vendors.length > 0 && !this.createForm.vendor_id) {
          this.createForm.vendor_id = this.vendors[0].id
        }
      } catch (err) {
        console.error('Failed to load vendors:', err)
      }
    },
    openCreateDialog() {
      this.createForm = {
        po_no: 'PO-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-' + String(Math.floor(Math.random() * 1000)).padStart(3, '0'),
        vendor_id: this.vendors[0]?.id || '',
        order_date: new Date().toISOString().slice(0, 10),
        expected_date: '',
        items: [{ item_id: null, qty: 1, unit_price: 0 }]
      }
      this.showCreateDialog = true
    },
    closeCreateDialog() {
      this.showCreateDialog = false
    },
    addLineItem() {
      this.createForm.items.push({ item_id: null, qty: 1, unit_price: 0 })
    },
    removeLineItem(idx) {
      this.createForm.items.splice(idx, 1)
    },
    async submitCreatePO() {
      const validItems = this.createForm.items.filter(i => i.item_id && i.qty > 0)
      if (validItems.length === 0) {
        alert('請至少填寫一項有效的商品')
        return
      }
      this.creatingPO = true
      try {
        const payload = {
          tenant_id: 1,
          po_no: this.createForm.po_no,
          vendor_id: parseInt(this.createForm.vendor_id),
          order_date: this.createForm.order_date,
          expected_date: this.createForm.expected_date || null,
          items: validItems.map(i => ({
            item_id: parseInt(i.item_id),
            qty: parseFloat(i.qty),
            unit_price: parseFloat(i.unit_price || 0)
          }))
        }
        await supabase.from('erp_purchase-orders/', payload)
        alert('採購單建立成功！')
        this.closeCreateDialog()
        this.fetchPurchaseOrders()
      } catch (err) {
        alert('建立失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.creatingPO = false
      }
    },
    async fetchPurchaseOrders() {
      this.loading = true
      try {
        const params = { tenant_id: 1 }
        if (this.filterStatus) params.status = this.filterStatus
        const res = await supabase.from('erp_purchase-orders/', { params })
        this.purchaseOrders = res.data
      } catch (err) {
        console.error('Failed to load purchase orders:', err)
        alert('載入採購單失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.loading = false
      }
    },
    async openReceiveDialog(po) {
      this.selectedPO = po
      this.receiveResult = null
      this.receiveForm = {
        warehouse_id: 1,
        received_date: new Date().toISOString().slice(0, 10)
      }

      // Fetch PO details
      try {
        const res = await this.$api.get(`/purchase-orders/${po.id}`)
        const detail = res.data
        this.poItems = detail.items || []

        // Build receive items map
        this.receiveItems = {}
        for (const item of this.poItems) {
          const remaining = parseFloat(item.qty) - parseFloat(item.received_qty || 0)
          this.receiveItems[item.item_id] = {
            receive_qty: remaining > 0 ? remaining : 0,
            lot_no: `LOT-${po.po_no}-${item.item_id}`,
            unit_cost: item.unit_price
          }
        }
      } catch (err) {
        console.error('Failed to load PO details:', err)
        // Fallback: try to build items from the list response
        this.poItems = []
      }

      this.showReceiveDialog = true
    },
    closeReceiveDialog() {
      this.showReceiveDialog = false
      this.selectedPO = null
      this.poItems = []
      this.receiveItems = {}
      this.receiveResult = null
    },
    async submitReceive() {
      if (!this.selectedPO) return

      // Build items array from receiveItems (only those with qty > 0)
      const items = Object.entries(this.receiveItems)
        .filter(([_, v]) => v.receive_qty > 0)
        .map(([item_id, v]) => ({
          item_id: parseInt(item_id),
          receive_qty: v.receive_qty,
          lot_no: v.lot_no || `LOT-${this.selectedPO.po_no}-${item_id}`,
          unit_cost: v.unit_cost
        }))

      if (items.length === 0) {
        alert('請輸入至少一項商品的驗收數量')
        return
      }

      this.receiving = true
      try {
        const payload = {
          warehouse_id: this.receiveForm.warehouse_id,
          received_date: this.receiveForm.received_date || undefined,
          items
        }
        const res = await this.$api.post(`/purchase-orders/${this.selectedPO.id}/receive`, payload)
        this.receiveResult = res.data
        this.fetchPurchaseOrders()
      } catch (err) {
        alert('進貨驗收失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.receiving = false
      }
    },
    statusLabel(status) {
      const labels = {
        PENDING: '待收貨',
        PARTIALLY_RECEIVED: '部分收貨',
        RECEIVED: '已完成',
        CANCELLED: '已取消'
      }
      return labels[status] || status
    },
    statusBadge(status) {
      const badges = {
        PENDING: 'badge badge-warning',
        PARTIALLY_RECEIVED: 'badge badge-info',
        RECEIVED: 'badge badge-success',
        CANCELLED: 'badge badge-secondary'
      }
      return badges[status] || 'badge'
    }
  }
}
</script>

<style scoped>
.page-container { padding: 2rem; max-width: 1400px; margin: 0 auto; }
.page-header { margin-bottom: 1.5rem; }
.page-header h1 { font-size: 2rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem; }
.subtitle { color: var(--text-secondary); font-size: 0.95rem; }

.action-bar { display: flex; justify-content: space-between; align-items: center; }
.filter-group { display: flex; gap: 0.75rem; align-items: center; }
.filter-select {
  padding: 0.5rem 1rem;
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  background: rgba(255,255,255,0.05);
  color: var(--text-primary);
  font-size: 0.9rem;
}

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
.font-mono { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 0.9rem; }
.text-center { text-align: center; }
.text-muted { color: var(--text-muted); }

.btn { display: inline-flex; align-items: center; gap: 0.4rem; padding: 0.5rem 1rem; border: none; border-radius: var(--radius-button); font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.btn-sm { padding: 0.35rem 0.75rem; font-size: 0.8rem; }
.btn-success { background: #22c55e; color: white; }
.btn-success:hover:not(:disabled) { background: #16a34a; }
.btn-secondary { background: rgba(255,255,255,0.1); color: var(--text-primary); }
.btn-secondary:hover { background: rgba(255,255,255,0.15); }
.btn-primary { background: var(--color-primary); color: white; }
.btn-primary:hover { opacity: 0.9; }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

.badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; }
.badge-success { background: rgba(34,197,94,0.15); color: #22c55e; }
.badge-warning { background: rgba(234,179,8,0.15); color: #eab308; }
.badge-info { background: rgba(59,130,246,0.15); color: #3b82f6; }
.badge-secondary { background: rgba(255,255,255,0.08); color: var(--text-muted); }

/* Modal */
.modal-backdrop { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-card { width: 90%; max-width: 600px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); padding: 1.5rem; max-height: 90vh; overflow-y: auto; }
.modal-card h3 { margin-bottom: 1rem; color: var(--text-primary); }
.modal-actions { display: flex; justify-content: flex-end; gap: 0.75rem; border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem; position: sticky; bottom: 0; background: inherit; }

.receive-dialog-content { display: flex; flex-direction: column; gap: 1rem; }
.dialog-info { background: rgba(255,255,255,0.03); border-radius: var(--radius-input); padding: 1rem; }
.info-row { display: flex; justify-content: space-between; padding: 0.3rem 0; }
.info-label { color: var(--text-muted); font-size: 0.85rem; }
.info-value { font-weight: 600; }

.line-items-section { background: rgba(255,255,255,0.02); border-radius: var(--radius-input); padding: 1rem; }
.line-items-section h4 { margin-bottom: 0.75rem; font-size: 0.9rem; color: var(--text-muted); }
.mini-table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
.mini-table th { text-align: left; padding: 0.4rem 0.5rem; color: var(--text-muted); border-bottom: 1px solid var(--border-glass); }
.mini-table td { padding: 0.4rem 0.5rem; }
.qty-input, .lot-input {
  width: 80px;
  padding: 0.3rem 0.5rem;
  border: 1px solid var(--border-glass);
  border-radius: 0.4rem;
  background: rgba(255,255,255,0.05);
  color: var(--text-primary);
  font-size: 0.85rem;
}
.lot-input { width: 120px; }

.form-group { margin-bottom: 0.75rem; }
.form-group label { display: block; margin-bottom: 0.4rem; font-size: 0.85rem; color: var(--text-muted); }
.form-group .required { color: #ef4444; }
.form-group input, .form-group select {
  width: 100%;
  padding: 0.6rem 0.85rem;
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  background: rgba(255,255,255,0.05);
  color: var(--text-primary);
  font-size: 0.9rem;
  box-sizing: border-box;
}
.form-group input:focus, .form-group select:focus { outline: none; border-color: var(--color-primary); }

.result-panel { background: rgba(34,197,94,0.08); border: 1px solid rgba(34,197,94,0.2); border-radius: var(--radius-input); padding: 1rem; margin-top: 1rem; }
.result-panel h4 { margin-bottom: 0.75rem; color: #22c55e; font-size: 0.9rem; }
.result-message { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.75rem; }
.result-message span { font-size: 0.9rem; }
.result-message strong { color: #22c55e; }
.lots-summary { padding-top: 0.75rem; border-top: 1px solid rgba(34,197,94,0.2); }
.result-label { font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.4rem; }
.lot-row { display: flex; justify-content: space-between; font-size: 0.8rem; padding: 0.2rem 0; color: var(--text-muted); }

.action-group { display: flex; gap: 0.75rem; }
.btn-outline { background: transparent; border: 1px solid var(--border-glass); color: var(--text-primary); }
.btn-outline:hover { background: rgba(255,255,255,0.05); }
.btn-icon { background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 0.8rem; padding: 0.2rem 0.4rem; }
.btn-icon:hover { color: #ef4444; }
.create-dialog-content { display: flex; flex-direction: column; gap: 1rem; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.line-items-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem; }
.line-items-header h4 { margin: 0; font-size: 0.9rem; color: var(--text-muted); }
.mini-table tfoot td { border-top: 1px solid var(--border-glass); padding-top: 0.5rem; font-weight: 600; }
.total-label { text-align: right; color: var(--text-muted); font-size: 0.85rem; }
.total-value { font-size: 1rem; color: var(--color-primary); }
.subtotal { font-weight: 600; white-space: nowrap; }
.item-id-input { width: 70px; }
.price-input { width: 90px; }
</style>