<template>
  <div class="data-admin-container animate-fade-in">
    <div class="header-section">
      <h1>資料庫管理與大數據中心</h1>
      <p class="subtitle">前台全面控制所有資料庫新增、修改、刪除、查詢及舊資料導入</p>
    </div>

    <!-- Legacy Data Import Card -->
    <div class="glass-card import-card mb-6">
      <div class="import-header">
        <div class="import-title">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-indigo-400"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          <h2>舊系統歷史資料一鍵導入</h2>
        </div>
        <button class="btn btn-primary" :disabled="importing" @click="triggerLegacyImport">
          <span v-if="importing">正在導入歷史數據...</span>
          <span v-else>開始導入 magic_baby 備份</span>
        </button>
      </div>
      <p class="desc-text">此操作將掃描 <code>/Volumes/Data_SSD/ERP專案/</code> 資料夾下的所有 <code>.mysql5</code> 備份檔，自動解析客戶 (CRM)、商品 (SKU)、尺寸顏色、與倉庫，並倒進當前運行的資料庫中。</p>
      <div v-if="importResult" class="import-result-badge mt-4" :class="importResult.status === 'ok' ? 'success' : 'error'">
        <div v-if="importResult.status === 'ok'">
          🎉 導入成功！共導入: 
          <strong>客戶(CRM): {{ importResult.imported_customers }} 筆</strong> | 
          <strong>商品(SKU): {{ importResult.imported_items }} 筆</strong> | 
          <strong>倉庫: {{ importResult.imported_warehouses }} 筆</strong>
        </div>
        <div v-else>
          ❌ 導入出錯: {{ importResult.message }}
        </div>
      </div>
    </div>

    <!-- Main Workspace Tabs -->
    <div class="tabs-header">
      <button 
        class="tab-btn" 
        :class="{ active: activeTab === 'crud' }" 
        @click="activeTab = 'crud'"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        <span>資料表增刪改查 (CRUD)</span>
      </button>
      <button 
        class="tab-btn" 
        :class="{ active: activeTab === 'sql' }" 
        @click="activeTab = 'sql'"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
        <span>任意 SQL 查詢器 (SQL Terminal)</span>
      </button>
    </div>

    <!-- Tab 1: CRUD Manager -->
    <div v-show="activeTab === 'crud'" class="glass-card tab-content">
      <div class="crud-toolbar">
        <div class="table-selector">
          <label>選擇資料表：</label>
          <select v-model="selectedTable" @change="fetchTableData(1)">
            <option v-for="(info, tName) in tablesSchema" :key="tName" :value="tName">
              {{ tName }} ({{ translateTableName(tName) }})
            </option>
          </select>
        </div>
        
        <div class="search-box">
          <input 
            type="text" 
            v-model="searchText" 
            placeholder="搜尋字串欄位..." 
            @keyup.enter="fetchTableData(1)"
          />
          <button class="btn btn-secondary" @click="fetchTableData(1)">搜尋</button>
        </div>

        <button class="btn btn-primary ml-auto" @click="openAddModal">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mr-1"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          新增項目
        </button>
      </div>

      <!-- Schema Column Legend -->
      <div class="column-legend" v-if="currentTableInfo">
        <strong>欄位結構：</strong>
        <span v-for="col in currentTableInfo.columns" :key="col.name" class="col-pill" :class="{ pk: col.primary_key }">
          {{ col.name }} <span class="col-type">({{ col.type }})</span>
        </span>
      </div>

      <!-- Data Table -->
      <div class="table-wrapper">
        <div v-if="loading" class="loading-state">載入中...</div>
        <div v-else-if="tableRows.length === 0" class="empty-state">無符合的紀錄</div>
        <table v-else>
          <thead>
            <tr>
              <th v-for="col in tableColumns" :key="col">{{ col }}</th>
              <th style="width: 150px; text-align: center;">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in tableRows" :key="row.id || row[tableColumns[0]]">
              <td v-for="col in tableColumns" :key="col">
                <span class="truncate-cell" :title="String(row[col])">{{ formatValue(row[col]) }}</span>
              </td>
              <td class="action-cell">
                <button class="btn-icon edit" @click="openEditModal(row)">
                  編輯
                </button>
                <button class="btn-icon delete" @click="deleteRow(row)">
                  刪除
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div class="pagination-footer" v-if="totalPages > 1">
        <span>顯示第 {{ (currentPage - 1) * limit + 1 }} 至 {{ Math.min(currentPage * limit, totalRows) }} 筆，共 {{ totalRows }} 筆</span>
        <div class="pagination-btns">
          <button class="btn btn-secondary" :disabled="currentPage === 1" @click="fetchTableData(currentPage - 1)">上一頁</button>
          <span class="page-num">{{ currentPage }} / {{ totalPages }}</span>
          <button class="btn btn-secondary" :disabled="currentPage === totalPages" @click="fetchTableData(currentPage + 1)">下一頁</button>
        </div>
      </div>
    </div>

    <!-- Tab 2: SQL Terminal -->
    <div v-show="activeTab === 'sql'" class="glass-card tab-content">
      <h2>執行任意 SQL 語句</h2>
      <p class="desc-text mb-4">可以直接輸入 <code>SELECT</code>, <code>INSERT</code>, <code>UPDATE</code>, <code>DELETE</code> 等查詢語句。</p>
      
      <div class="sql-terminal-box">
        <textarea 
          v-model="sqlQuery" 
          rows="6" 
          placeholder="例如: SELECT * FROM customers WHERE type = 'AGENT' LIMIT 10;"
        ></textarea>
        <div class="terminal-footer">
          <button class="btn btn-primary" :disabled="executingSql" @click="runCustomSql">
            {{ executingSql ? '正在執行 SQL...' : '執行 SQL 語句' }}
          </button>
        </div>
      </div>

      <!-- SQL Console Feedback -->
      <div v-if="sqlError" class="sql-error-box mt-4">
        <strong>⚠️ 執行出錯:</strong> {{ sqlError }}
      </div>

      <div v-if="sqlSuccess" class="sql-success-box mt-4">
        <strong>✅ 成功:</strong> {{ sqlSuccess }}
      </div>

      <!-- Query Output Table -->
      <div v-if="sqlResult" class="sql-result-container mt-6">
        <h3>查詢結果 (共 {{ sqlResult.count || sqlResult.rowcount || 0 }} 筆)</h3>
        <div class="table-wrapper mt-2" v-if="sqlResult.columns && sqlResult.columns.length">
          <table>
            <thead>
              <tr>
                <th v-for="col in sqlResult.columns" :key="col">{{ col }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(row, idx) in sqlResult.rows" :key="idx">
                <td v-for="col in sqlResult.columns" :key="col">{{ formatValue(row[col]) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="empty-state mt-2">
          該語句無傳回任何資料表結構 (已套用至 {{ sqlResult.rowcount }} 列)
        </div>
      </div>
    </div>

    <!-- Add/Edit Dynamic Modal -->
    <div class="modal-backdrop" v-if="showModal">
      <div class="modal-card glass-card">
        <h3>{{ isEditMode ? '修改資料' : '新增資料' }} - {{ selectedTable }}</h3>
        <div class="modal-form">
          <div v-for="col in currentTableInfo.columns" :key="col.name" class="form-group">
            <!-- Do not show primary key ID input in add mode -->
            <template v-if="!(col.primary_key && !isEditMode)">
              <label>{{ col.name }} <span class="type-hint">({{ col.type }})</span></label>
              
              <!-- Special input types -->
              <input 
                v-if="col.primary_key" 
                v-model="modalData[col.name]" 
                disabled 
                type="text"
              />
              <select v-else-if="col.type.includes('BOOLEAN')" v-model="modalData[col.name]">
                <option :value="true">True</option>
                <option :value="false">False</option>
              </select>
              <input 
                v-else-if="col.type.includes('INTEGER') || col.type.includes('NUMERIC') || col.type.includes('FLOAT')" 
                v-model.number="modalData[col.name]" 
                type="number" 
                step="any"
              />
              <input 
                v-else 
                v-model="modalData[col.name]" 
                type="text"
              />
            </template>
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeModal">取消</button>
          <button class="btn btn-primary" @click="saveModalData">保存</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'DataAdmin',
  data() {
    return {
      activeTab: 'crud',
      tablesSchema: {},
      selectedTable: 'customers',
      searchText: '',
      loading: false,
      tableColumns: [],
      tableRows: [],
      currentPage: 1,
      limit: 15,
      totalRows: 0,
      
      // SQL Terminal
      sqlQuery: '',
      executingSql: false,
      sqlResult: null,
      sqlError: null,
      sqlSuccess: null,

      // Import Legacy
      importing: false,
      importResult: null,

      // Modal
      showModal: false,
      isEditMode: false,
      modalData: {},
      currentEditingId: null
    }
  },
  computed: {
    currentTableInfo() {
      return this.tablesSchema[this.selectedTable] || null
    },
    totalPages() {
      return Math.ceil(this.totalRows / this.limit)
    }
  },
  mounted() {
    this.fetchTablesSchema()
  },
  methods: {
    async fetchTablesSchema() {
      try {
        const res = await supabase.from('erp_db/tables')
        this.tablesSchema = res.data
        if (res.data && Object.keys(res.data).length > 0) {
          if (res.data['customers']) {
            this.selectedTable = 'customers'
          } else {
            this.selectedTable = Object.keys(res.data)[0]
          }
          this.fetchTableData(1)
        }
      } catch (err) {
        console.error('Failed to fetch table schema:', err)
      }
    },
    async fetchTableData(page = 1) {
      this.loading = true
      this.currentPage = page
      try {
        let url = `/db/tables/${this.selectedTable}?page=${page}&limit=${this.limit}`
        if (this.searchText) {
          url += `&search=${encodeURIComponent(this.searchText)}`
        }
        const res = await this.$api.get(url)
        const data = res.data
        this.tableColumns = data.columns || []
        this.tableRows = data.rows || []
        this.totalRows = data.total || 0
      } catch (err) {
        console.error('Failed to fetch table data:', err)
      } finally {
        this.loading = false
      }
    },
    translateTableName(name) {
      const mapping = {
        'tenants': '租戶/公司主檔',
        'customers': '客戶主檔 (CRM)',
        'items': '商品款式主檔 (SKU)',
        'warehouses': '倉庫主檔',
        'channels': '銷售通路',
        'payment_methods': '付款方式',
        'collection_targets': '請款對象',
        'orders': '直營銷貨主表',
        'order_items': '直營銷貨明細',
        'consignments': '託售出貨主表',
        'consignment_items': '託售出貨明細',
        'settlements': '月結對帳單主表',
        'settlement_items': '月結對帳明細',
        'account_receivables': '應收帳款明細',
        'general_ledger': '會計總帳分錄',
        'inventory': '實體/託售庫存量',
        'inventory_lots': '先進先出Lot批次',
        'inventory_transactions': '庫存變動履歷'
      }
      return mapping[name] || '系統表'
    },
    formatValue(val) {
      if (val === null || val === undefined) return 'NULL'
      if (typeof val === 'boolean') return val ? 'True' : 'False'
      return val
    },
    // CRUD Operations
    openAddModal() {
      this.isEditMode = false
      this.modalData = {}
      
      // Pre-populate defaults
      this.currentTableInfo.columns.forEach(col => {
        if (col.name === 'tenant_id') {
          this.modalData[col.name] = 1
        } else if (col.type.includes('BOOLEAN')) {
          this.modalData[col.name] = true
        } else if (col.name !== 'id') {
          this.modalData[col.name] = col.default !== 'None' ? col.default : ''
        }
      })
      this.showModal = true
    },
    openEditModal(row) {
      this.isEditMode = true
      this.modalData = { ...row }
      // Locate the primary key id
      const pk = this.currentTableInfo.columns.find(col => col.primary_key)
      this.currentEditingId = pk ? row[pk.name] : row.id
      this.showModal = true
    },
    closeModal() {
      this.showModal = false
      this.modalData = {}
      this.currentEditingId = null
    },
    async saveModalData() {
      try {
        const method = this.isEditMode ? 'put' : 'post'
        const url = this.isEditMode
          ? `/db/tables/${this.selectedTable}/${this.currentEditingId}`
          : `/db/tables/${this.selectedTable}`

        const res = await this.$api[method](url, this.modalData)
        const result = res.data
        alert(result.message || '操作成功')
        this.closeModal()
        this.fetchTableData(this.currentPage)
      } catch (err) {
        alert('操作失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async deleteRow(row) {
      const pk = this.currentTableInfo.columns.find(col => col.primary_key)
      const id = pk ? row[pk.name] : row.id
      if (!confirm(`確定要刪除此筆記錄 (ID: ${id}) 嗎？`)) return

      try {
        const res = await this.$api.delete(`/db/tables/${this.selectedTable}/${id}`)
        const result = res.data
        alert(result.message || '刪除成功')
        this.fetchTableData(this.currentPage)
      } catch (err) {
        alert('刪除失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    // Custom SQL Execution
    async runCustomSql() {
      if (!this.sqlQuery.trim()) return
      this.executingSql = true
      this.sqlResult = null
      this.sqlError = null
      this.sqlSuccess = null

      try {
        const res = await supabase.from('erp_db/query', { sql: this.sqlQuery })
        const data = res.data
        this.sqlResult = data
        if (data.type === 'write') {
          this.sqlSuccess = `${data.message} (影響了 ${data.rowcount} 行)`
        } else {
          this.sqlSuccess = `查詢執行成功，傳回 ${data.count} 列`
        }
      } catch (err) {
        this.sqlError = (err.response?.data?.detail || err.message)
      } finally {
        this.executingSql = false
      }
    },
    // Import Legacy Data Trigger
    async triggerLegacyImport() {
      if (!confirm('此操作將會把 /Volumes/Data_SSD/ERP專案 內 16 個 MySQL 備份資料匯入當前資料庫，是否繼續？')) return
      this.importing = true
      this.importResult = null

      try {
        const res = await supabase.from('erp_db/import-legacy')
        const data = res.data
        this.importResult = data
        this.fetchTablesSchema() // Refresh to load newly imported data
      } catch (err) {
        this.importResult = { status: 'error', message: err.response?.data?.detail || err.message }
      } finally {
        this.importing = false
      }
    }
  }
}
</script>

<style scoped>
.data-admin-container {
  max-width: 100%;
}
.header-section {
  margin-bottom: 2rem;
}
.mb-6 { margin-bottom: 1.5rem; }
.mt-4 { margin-top: 1rem; }
.mt-6 { margin-top: 1.5rem; }
.mt-2 { margin-top: 0.5rem; }
.mr-1 { margin-right: 0.25rem; }
.ml-auto { margin-left: auto; }

/* Import Legacy Card */
.import-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}
.import-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.desc-text {
  font-size: 0.9rem;
  color: var(--text-muted);
}
.desc-text code {
  background: rgba(255, 255, 255, 0.08);
  padding: 0.1rem 0.3rem;
  border-radius: 4px;
  color: #ff79c6;
}
.import-result-badge {
  padding: 0.75rem 1rem;
  border-radius: 8px;
  font-size: 0.95rem;
}
.import-result-badge.success {
  background: rgba(16, 185, 129, 0.15);
  color: var(--color-success);
  border: 1px solid rgba(16, 185, 129, 0.3);
}
.import-result-badge.error {
  background: rgba(239, 68, 68, 0.15);
  color: var(--color-danger);
  border: 1px solid rgba(239, 68, 68, 0.3);
}

/* Tabs */
.tabs-header {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid var(--border-glass);
  padding-bottom: 0.5rem;
}
.tab-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  padding: 0.6rem 1.2rem;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: var(--transition-smooth);
  border-radius: 8px 8px 0 0;
  position: relative;
}
.tab-btn:hover {
  color: #fff;
}
.tab-btn.active {
  color: var(--color-primary);
}
.tab-btn.active::after {
  content: '';
  position: absolute;
  bottom: -0.5rem;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--color-primary);
  box-shadow: 0 0 8px var(--color-primary);
}

/* CRUD Workspace */
.crud-toolbar {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}
.table-selector {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.table-selector select {
  min-width: 250px;
}
.search-box {
  display: flex;
  gap: 0.5rem;
  min-width: 300px;
}

.column-legend {
  background: rgba(255, 255, 255, 0.02);
  border: 1px solid var(--border-glass);
  border-radius: 8px;
  padding: 0.75rem 1rem;
  margin-bottom: 1.5rem;
  font-size: 0.85rem;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}
.col-pill {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--border-glass);
  border-radius: 4px;
  padding: 0.15rem 0.5rem;
  font-family: monospace;
}
.col-pill.pk {
  background: rgba(99, 102, 241, 0.15);
  color: #a5b4fc;
  border-color: rgba(99, 102, 241, 0.4);
}
.col-type {
  color: var(--text-muted);
  font-size: 0.75rem;
}

/* Table Design */
.table-wrapper {
  overflow-x: auto;
  min-height: 200px;
}
.loading-state, .empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 200px;
  color: var(--text-muted);
  font-size: 1.1rem;
}
.truncate-cell {
  display: inline-block;
  max-width: 220px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  vertical-align: middle;
}
.action-cell {
  display: flex;
  justify-content: center;
  gap: 0.5rem;
}
.btn-icon {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
  transition: var(--transition-smooth);
}
.btn-icon.edit {
  color: #60a5fa;
  background: rgba(96, 165, 250, 0.1);
  border: 1px solid rgba(96, 165, 250, 0.2);
}
.btn-icon.edit:hover {
  background: #60a5fa;
  color: #0b0f19;
}
.btn-icon.delete {
  color: #f87171;
  background: rgba(248, 113, 113, 0.1);
  border: 1px solid rgba(248, 113, 113, 0.2);
}
.btn-icon.delete:hover {
  background: #f87171;
  color: #0b0f19;
}

/* Pagination */
.pagination-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 1.5rem;
  font-size: 0.9rem;
  color: var(--text-muted);
}
.pagination-btns {
  display: flex;
  align-items: center;
  gap: 1rem;
}
.page-num {
  font-weight: 600;
  color: #fff;
}

/* SQL Terminal styles */
.sql-terminal-box {
  background: #0d1117;
  border: 1px solid var(--border-glass);
  border-radius: 8px;
  padding: 1rem;
}
.sql-terminal-box textarea {
  background: transparent;
  border: none;
  font-family: 'Courier New', Courier, monospace;
  font-size: 1.05rem;
  color: #39ff14; /* Matrix Green */
  line-height: 1.6;
  resize: vertical;
}
.sql-terminal-box textarea::placeholder {
  color: rgba(57, 255, 20, 0.4);
}
.sql-terminal-box textarea:focus {
  box-shadow: none;
  background: transparent;
}
.terminal-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 0.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
  padding-top: 0.75rem;
}
.sql-error-box {
  background: rgba(239, 68, 68, 0.1);
  color: #f87171;
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 6px;
  padding: 0.75rem 1rem;
  font-family: monospace;
}
.sql-success-box {
  background: rgba(16, 185, 129, 0.1);
  color: #34d399;
  border: 1px solid rgba(16, 185, 129, 0.3);
  border-radius: 6px;
  padding: 0.75rem 1rem;
}

/* Modal Backing */
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
  max-width: 600px;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 50px rgba(0,0,0,0.5);
  animation: modalIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
}
@keyframes modalIn {
  from { transform: scale(0.9) translateY(20px); opacity: 0; }
  to { transform: scale(1) translateY(0); opacity: 1; }
}
.modal-form {
  overflow-y: auto;
  padding: 1rem 0;
  margin: 1rem 0;
  flex: 1;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  border-top: 1px solid var(--border-glass);
  padding-top: 1rem;
}
.type-hint {
  font-size: 0.75rem;
  color: var(--text-dark);
  font-family: monospace;
}
</style>
