<template>
  <div class="page-container animate-fade-in">
    <div class="page-header">
      <h1>🏭 生產管理系統</h1>
      <p class="subtitle">工單管理與完工入庫流程</p>
    </div>

    <!-- Action Bar -->
    <div class="glass-card" style="margin-bottom: 1.5rem;">
      <div class="action-bar">
        <div class="filter-group">
          <select v-model="filterStatus" @change="fetchWorkOrders" class="filter-select">
            <option value="">全部狀態</option>
            <option value="PENDING">待執行</option>
            <option value="IN_PROGRESS">生產中</option>
            <option value="COMPLETED">已完成</option>
            <option value="CANCELLED">已取消</option>
          </select>
        </div>
        <div class="action-group">
          <button class="btn btn-outline" @click="openCreateDialog">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            新建工單
          </button>
          <button class="btn btn-primary" @click="fetchWorkOrders">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/></svg>
            刷新
          </button>
        </div>
      </div>
    </div>

    <!-- Work Orders Table -->
    <div class="glass-card">
      <table class="data-table">
        <thead>
          <tr>
            <th>工單編號</th>
            <th>產品</th>
            <th>數量</th>
            <th>預計完工日</th>
            <th>實際完工日</th>
            <th>狀態</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="7" class="text-center text-muted" style="padding: 2rem;">載入中...</td>
          </tr>
          <tr v-else-if="workOrders.length === 0">
            <td colspan="7" class="text-center text-muted" style="padding: 2rem;">尚無工單資料</td>
          </tr>
          <tr v-else v-for="wo in workOrders" :key="wo.id">
            <td class="font-mono">{{ wo.wo_no }}</td>
            <td>{{ wo.product_id }}</td>
            <td>{{ wo.qty }}</td>
            <td>{{ wo.planned_end || '-' }}</td>
            <td>{{ wo.actual_end || '-' }}</td>
            <td><span :class="statusBadge(wo.status)">{{ statusLabel(wo.status) }}</span></td>
            <td>
              <button
                v-if="wo.status === 'PENDING' || wo.status === 'IN_PROGRESS'"
                class="btn btn-sm btn-success"
                @click="openCompleteDialog(wo)"
              >
                完工入庫
              </button>
              <button
                v-else-if="wo.status === 'PENDING'"
                class="btn btn-sm btn-secondary"
                @click="updateStatus(wo, 'IN_PROGRESS')"
              >
                開始生產
              </button>
              <span v-else class="text-muted">-</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Complete Dialog -->
    <div class="modal-backdrop" v-if="showCompleteDialog">
      <div class="modal-card glass-card">
        <h3>完工入庫</h3>
        <div v-if="selectedWO" class="complete-dialog-content">
          <div class="dialog-info">
            <div class="info-row">
              <span class="info-label">工單編號</span>
              <span class="info-value font-mono">{{ selectedWO.wo_no }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">產品</span>
              <span class="info-value">{{ selectedWO.product_id }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">生產數量</span>
              <span class="info-value">{{ selectedWO.qty }}</span>
            </div>
          </div>

          <div class="form-group">
            <label>入庫倉庫 <span class="required">*</span></label>
            <select v-model="completeForm.warehouse_id" required>
              <option value="" disabled>請選擇倉庫</option>
              <option v-for="wh in warehouses" :key="wh.id" :value="wh.id">
                {{ wh.name || '倉庫 ' + wh.id }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>人工成本（分攤）</label>
            <input
              type="number"
              v-model.number="completeForm.labor_cost"
              min="0"
              step="0.01"
              placeholder="0.00"
            />
          </div>

          <div class="form-group">
            <label>完工日期</label>
            <input type="date" v-model="completeForm.completed_date" />
          </div>
        </div>

        <!-- Result Panel -->
        <div v-if="completeResult" class="result-panel">
          <h4>完工入庫結果</h4>
          <div class="result-grid">
            <div class="result-item">
              <span class="result-label">完工數量</span>
              <span class="result-value">{{ completeResult.completed_qty }}</span>
            </div>
            <div class="result-item">
              <span class="result-label">原料成本</span>
              <span class="result-value">${{ completeResult.material_costs?.toFixed(2) }}</span>
            </div>
            <div class="result-item">
              <span class="result-label">人工成本</span>
              <span class="result-value">${{ completeResult.labor_costs?.toFixed(2) }}</span>
            </div>
            <div class="result-item">
              <span class="result-label">成品單位成本</span>
              <span class="result-value">${{ completeResult.unit_cost?.toFixed(4) }}</span>
            </div>
            <div class="result-item highlight">
              <span class="result-label">成品總成本</span>
              <span class="result-value">${{ completeResult.total_product_cost?.toFixed(2) }}</span>
            </div>
          </div>
          <div v-if="completeResult.consumed_materials?.length" class="consumed-materials">
            <div class="result-label">原料消耗明細</div>
            <div v-for="mat in completeResult.consumed_materials" :key="mat.item_id" class="material-row">
              <span>料號 {{ mat.item_id }}</span>
              <span>數量 {{ mat.qty }}</span>
              <span>成本 ${{ (mat.cost * mat.qty).toFixed(2) }}</span>
            </div>
          </div>
        </div>

        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeCompleteDialog">取消</button>
          <button
            class="btn btn-success"
            @click="submitComplete"
            :disabled="!completeForm.warehouse_id || completing"
          >
            {{ completing ? '處理中...' : '確認完工入庫' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Create Work Order Dialog -->
    <div class="modal-backdrop" v-if="showCreateDialog">
      <div class="modal-card glass-card">
        <h3>新建工單</h3>
        <div class="create-dialog-content">
          <div class="form-row">
            <div class="form-group">
              <label>工單編號 <span class="required">*</span></label>
              <input type="text" v-model="createForm.wo_no" required placeholder="例如: WO-20250608-001" />
            </div>
            <div class="form-group">
              <label>成品 (item_id) <span class="required">*</span></label>
              <input type="number" v-model.number="createForm.product_id" min="1" placeholder="輸入商品 ID" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>生產數量 <span class="required">*</span></label>
              <input type="number" v-model.number="createForm.qty" min="1" step="1" placeholder="數量" />
            </div>
            <div class="form-group">
              <label>BOM 配方 (選填)</label>
              <input type="number" v-model.number="createForm.bom_id" min="1" placeholder="如有配方請填 ID" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>預計開工日</label>
              <input type="date" v-model="createForm.planned_start" />
            </div>
            <div class="form-group">
              <label>預計完工日</label>
              <input type="date" v-model="createForm.planned_end" />
            </div>
          </div>

          <!-- Manual Material Items (optional) -->
          <div class="line-items-section">
            <div class="line-items-header">
              <h4>原料明細（選填，若無 BOM 才需填寫）</h4>
            </div>
            <table class="mini-table">
              <thead>
                <tr>
                  <th>原料 item_id</th>
                  <th>數量</th>
                  <th>單價成本</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(item, idx) in createForm.items" :key="idx">
                  <td><input type="number" v-model.number="item.item_id" min="1" placeholder="ID" class="item-id-input" /></td>
                  <td><input type="number" v-model.number="item.qty" min="0.01" step="0.01" class="qty-input" /></td>
                  <td><input type="number" v-model.number="item.cost_price" min="0" step="0.01" class="price-input" /></td>
                  <td><button type="button" class="btn-icon" @click="removeCreateItem(idx)" v-if="createForm.items.length > 1">✕</button></td>
                </tr>
              </tbody>
            </table>
            <button type="button" class="btn btn-sm btn-outline" @click="addCreateItem" style="margin-top: 0.5rem;">+ 新增原料</button>
          </div>
        </div>

        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeCreateDialog">取消</button>
          <button
            class="btn btn-primary"
            @click="submitCreateWO"
            :disabled="creatingWO || !createForm.wo_no || !createForm.product_id || !createForm.qty"
          >
            {{ creatingWO ? '建立中...' : '建立工單' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'WorkOrders',
  data() {
    return {
      workOrders: [],
      loading: false,
      filterStatus: '',
      showCompleteDialog: false,
      selectedWO: null,
      completing: false,
      warehouses: [
        { id: 1, name: '總公司倉庫' },
        { id: 2, name: '門市倉庫 A' },
        { id: 3, name: '門市倉庫 B' }
      ],
      completeForm: {
        warehouse_id: 1,
        labor_cost: 0,
        completed_date: new Date().toISOString().slice(0, 10)
      },
      completeResult: null,

      // Create WO
      showCreateDialog: false,
      creatingWO: false,
      createForm: {
        wo_no: 'WO-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-001',
        product_id: null,
        qty: 10,
        bom_id: null,
        planned_start: '',
        planned_end: '',
        items: []
      }
    }
  },
  mounted() {
    this.fetchWorkOrders()
  },
  methods: {
    openCreateDialog() {
      this.createForm = {
        wo_no: 'WO-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-' + String(Math.floor(Math.random() * 1000)).padStart(3, '0'),
        product_id: null,
        qty: 10,
        bom_id: null,
        planned_start: new Date().toISOString().slice(0, 10),
        planned_end: '',
        items: [{ item_id: null, qty: 1, cost_price: 0 }]
      }
      this.showCreateDialog = true
    },
    closeCreateDialog() {
      this.showCreateDialog = false
    },
    addCreateItem() {
      this.createForm.items.push({ item_id: null, qty: 1, cost_price: 0 })
    },
    removeCreateItem(idx) {
      this.createForm.items.splice(idx, 1)
    },
    async submitCreateWO() {
      const validItems = this.createForm.items.filter(i => i.item_id && i.qty > 0)
      this.creatingWO = true
      try {
        const payload = {
          tenant_id: 1,
          wo_no: this.createForm.wo_no,
          product_id: parseInt(this.createForm.product_id),
          qty: parseFloat(this.createForm.qty),
          bom_id: this.createForm.bom_id ? parseInt(this.createForm.bom_id) : null,
          planned_start: this.createForm.planned_start || null,
          planned_end: this.createForm.planned_end || null,
          items: validItems.map(i => ({
            item_id: parseInt(i.item_id),
            qty: parseFloat(i.qty),
            cost_price: parseFloat(i.cost_price || 0),
            type: 'MATERIAL'
          }))
        }
        await supabase.from('erp_work-orders/', payload)
        alert('工單建立成功！')
        this.closeCreateDialog()
        this.fetchWorkOrders()
      } catch (err) {
        alert('建立失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.creatingWO = false
      }
    },
    async fetchWorkOrders() {
      this.loading = true
      try {
        const params = { tenant_id: 1 }
        if (this.filterStatus) params.status = this.filterStatus
        const res = await supabase.from('erp_work-orders/', { params })
        this.workOrders = res.data
      } catch (err) {
        console.error('Failed to load work orders:', err)
        alert('載入工單失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.loading = false
      }
    },
    async updateStatus(wo, newStatus) {
      try {
        await this.$api.put(`/work-orders/${wo.id}/status?status=${newStatus}`)
        this.fetchWorkOrders()
      } catch (err) {
        alert('更新狀態失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    openCompleteDialog(wo) {
      this.selectedWO = wo
      this.completeForm = {
        warehouse_id: 1,
        labor_cost: 0,
        completed_date: new Date().toISOString().slice(0, 10)
      }
      this.completeResult = null
      this.showCompleteDialog = true
    },
    closeCompleteDialog() {
      this.showCompleteDialog = false
      this.selectedWO = null
      this.completeResult = null
    },
    async submitComplete() {
      if (!this.selectedWO) return
      this.completing = true
      try {
        const payload = {
          warehouse_id: this.completeForm.warehouse_id,
          labor_cost: this.completeForm.labor_cost || 0,
          completed_date: this.completeForm.completed_date || undefined
        }
        const res = await this.$api.post(`/work-orders/${this.selectedWO.id}/complete`, payload)
        this.completeResult = res.data
        this.fetchWorkOrders()
      } catch (err) {
        alert('完工入庫失敗: ' + (err.response?.data?.detail || err.message))
      } finally {
        this.completing = false
      }
    },
    statusLabel(status) {
      const labels = {
        PENDING: '待執行',
        IN_PROGRESS: '生產中',
        COMPLETED: '已完成',
        CANCELLED: '已取消'
      }
      return labels[status] || status
    },
    statusBadge(status) {
      const badges = {
        PENDING: 'badge badge-warning',
        IN_PROGRESS: 'badge badge-info',
        COMPLETED: 'badge badge-success',
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
.modal-card { width: 90%; max-width: 500px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); padding: 1.5rem; }
.modal-card h3 { margin-bottom: 1rem; color: var(--text-primary); }
.modal-actions { display: flex; justify-content: flex-end; gap: 0.75rem; border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem; }

.complete-dialog-content { display: flex; flex-direction: column; gap: 1rem; }
.dialog-info { background: rgba(255,255,255,0.03); border-radius: var(--radius-input); padding: 1rem; }
.info-row { display: flex; justify-content: space-between; padding: 0.3rem 0; }
.info-label { color: var(--text-muted); font-size: 0.85rem; }
.info-value { font-weight: 600; }

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
.result-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem; }
.result-item { display: flex; flex-direction: column; gap: 0.15rem; }
.result-item.highlight { grid-column: 1 / -1; background: rgba(34,197,94,0.1); padding: 0.5rem; border-radius: 0.5rem; }
.result-label { font-size: 0.75rem; color: var(--text-muted); }
.result-value { font-size: 0.95rem; font-weight: 600; color: var(--text-primary); }
.consumed-materials { margin-top: 0.75rem; padding-top: 0.75rem; border-top: 1px solid rgba(34,197,94,0.2); }
.material-row { display: flex; justify-content: space-between; font-size: 0.8rem; padding: 0.2rem 0; color: var(--text-muted); }

.action-group { display: flex; gap: 0.75rem; }
.btn-outline { background: transparent; border: 1px solid var(--border-glass); color: var(--text-primary); }
.btn-outline:hover { background: rgba(255,255,255,0.05); }
.btn-icon { background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 0.8rem; padding: 0.2rem 0.4rem; }
.btn-icon:hover { color: #ef4444; }
.create-dialog-content { display: flex; flex-direction: column; gap: 1rem; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.line-items-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem; }
.line-items-header h4 { margin: 0; font-size: 0.9rem; color: var(--text-muted); }
.line-items-section { background: rgba(255,255,255,0.02); border-radius: var(--radius-input); padding: 1rem; }
.mini-table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
.mini-table th { text-align: left; padding: 0.4rem 0.5rem; color: var(--text-muted); border-bottom: 1px solid var(--border-glass); }
.mini-table td { padding: 0.4rem 0.5rem; }
.item-id-input { width: 70px; }
.qty-input { width: 80px; }
.price-input { width: 90px; }
</style>