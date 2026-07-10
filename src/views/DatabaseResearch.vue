<template>
  <div class="animate-fade-in">
    <h1>資料庫研究分析</h1>
    <p class="subtitle">magicbaby_db.mysql5 (2.7GB, 910 Tables) - 舊系統結構透視</p>

    <!-- Database Overview Cards -->
    <div class="grid-cols-4">
      <div class="glass-card stat-card">
        <span class="stat-label">總表數量</span>
        <span class="stat-value" style="color: #6366f1;">910 <span style="font-size: 1rem; font-weight: normal;">Tables</span></span>
        <span class="stat-desc">DB 總公司資料庫</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">資料庫大小</span>
        <span class="stat-value" style="color: #10b981;">2.7 <span style="font-size: 1rem; font-weight: normal;">GB</span></span>
        <span class="stat-desc">magicbaby_db.mysql5</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">通路客戶數</span>
        <span class="stat-value" style="color: #f59e0b;">74 <span style="font-size: 1rem; font-weight: normal;">Channels</span></span>
        <span class="stat-desc">P001 - P074 (P064 缺號)</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">業務模組數</span>
        <span class="stat-value" style="color: #ef4444;">11 <span style="font-size: 1rem; font-weight: normal;">Modules</span></span>
        <span class="stat-desc">銷貨/採購/庫存/人事</span>
      </div>
    </div>

    <!-- Table Classification -->
    <div class="glass-card" style="margin-bottom: 2rem;">
      <h2>📊 Table 分類總覽 (Prefix Classification)</h2>
      <div class="table-classification">
        <div
          v-for="category in tableCategories"
          :key="category.prefix"
          class="category-item"
          @click="selectedCategory = category"
          :class="{ active: selectedCategory?.prefix === category.prefix }"
        >
          <span class="category-prefix">{{ category.prefix }}</span>
          <span class="category-count">{{ category.count }}</span>
          <span class="category-desc">{{ category.description }}</span>
        </div>
      </div>
    </div>

    <!-- Two Column Layout -->
    <div class="grid-cols-2">
      <!-- Key Business Tables -->
      <div class="glass-card">
        <h2>🔑 關鍵業務 Table 結構</h2>
        <div class="table-selector">
          <button
            v-for="table in keyTables"
            :key="table.name"
            class="table-tab"
            :class="{ active: selectedTable?.name === table.name }"
            @click="selectedTable = table"
          >
            {{ table.name }}
          </button>
        </div>
        <div v-if="selectedTable" class="table-structure">
          <h3>{{ selectedTable.name }} - {{ selectedTable.description }}</h3>
          <table>
            <thead>
              <tr>
                <th>欄位</th>
                <th>用途</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="field in selectedTable.fields" :key="field.name">
                <td class="field-name">{{ field.name }}</td>
                <td>{{ field.description }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- P-Channel Customer List -->
      <div class="glass-card">
        <h2>🏪 P-通路客戶 (P001-P074)</h2>
        <div class="search-box">
          <input
            type="text"
            v-model="channelSearch"
            placeholder="搜尋通路代號或名稱..."
            class="search-input"
          />
        </div>
        <div class="channel-list">
          <div
            v-for="channel in filteredChannels"
            :key="channel.code"
            class="channel-item"
          >
            <span class="channel-code">{{ channel.code }}</span>
            <span class="channel-name">{{ channel.name }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Migration Mapping -->
    <div class="glass-card" style="margin-top: 2rem;">
      <h2>🔄 新舊系統 Schema 對照 (Migration Mapping)</h2>
      <table>
        <thead>
          <tr>
            <th>舊系統 Table</th>
            <th>新系統 Table</th>
            <th>說明</th>
            <th>狀態</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="mapping in migrationMappings" :key="mapping.oldTable">
            <td class="field-name">{{ mapping.oldTable }}</td>
            <td>{{ mapping.newTable }}</td>
            <td>{{ mapping.description }}</td>
            <td>
              <span
                class="badge"
                :class="getStatusClass(mapping.status)"
              >
                {{ mapping.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Migration Recommendations -->
    <div class="glass-card" style="margin-top: 2rem;">
      <h2>📋 遷移建議 (Migration Recommendations)</h2>
      <div class="phase-list">
        <div class="phase-item phase-a">
          <span class="phase-label">Phase A</span>
          <span class="phase-title">基礎資料</span>
          <span class="phase-desc">tenants, warehouses, channels, items, customers</span>
        </div>
        <div class="phase-item phase-b">
          <span class="phase-label">Phase B</span>
          <span class="phase-title">庫存快照</span>
          <span class="phase-desc">inventory + inventory_lots 初始值</span>
        </div>
        <div class="phase-item phase-c">
          <span class="phase-label">Phase C</span>
          <span class="phase-title">歷史交易</span>
          <span class="phase-desc">orders, consignments, settlements, AR, GL</span>
        </div>
        <div class="phase-item phase-d">
          <span class="phase-label">Phase D</span>
          <span class="phase-title">並行雙寫驗證</span>
          <span class="phase-desc">新舊系統同步驗證</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const selectedCategory = ref(null)
const selectedTable = ref(null)
const channelSearch = ref('')

const tableCategories = [
  { prefix: 'f_', count: '~255', description: '財務 (AR/AP/GL/發票)' },
  { prefix: 'g_', count: '~195', description: '銷貨 (SO/客戶/促銷/報價)' },
  { prefix: 'i_', count: '~95', description: '庫存 (Item/交易/倉庫)' },
  { prefix: 'm_', count: '~90', description: '生產製造 (BOM/工單/成本)' },
  { prefix: 'p_', count: '~80', description: '採購 (PO/PQ/供應商)' },
  { prefix: 'pos_', count: '~55', description: 'POS 門市交易' },
  { prefix: 'h_', count: '~27', description: '人力資源 (班表/薪資)' },
  { prefix: 'pub_', count: '~20', description: '公共資料 (員工/部門/匯率)' },
  { prefix: 'sys_', count: '~16', description: '系統參數' },
  { prefix: 'cr_', count: '~13', description: '客戶註冊' },
  { prefix: 'clm_', count: '~6', description: '託售 (Consignment)' },
  { prefix: 'bas_', count: '~3', description: '基本地理 (城市/道路)' },
]

const keyTables = [
  {
    name: 'g_so',
    description: '直營銷貨單',
    fields: [
      { name: 'NO_SO', description: '銷貨單號 (PK)' },
      { name: 'DT_APPLY', description: '訂單日期 (YYYYMMDD)' },
      { name: 'ID_CUST', description: '客戶代號' },
      { name: 'AM_TOT / AM_SUM', description: '總金額 / 含稅合計' },
      { name: 'AM_TAX', description: '稅額' },
      { name: 'FG_FINISH', description: '結案旗標 (Y/N)' },
      { name: 'NO_GL', description: '對應傳票號' },
    ]
  },
  {
    name: 'clm_cust',
    description: '託售出貨單',
    fields: [
      { name: 'NO_CLM', description: '託售單號 (PK)' },
      { name: 'DT_APPLY / DT_CS', description: '申請日期 / 出貨日期' },
      { name: 'ID_CUST', description: '代理商代號' },
      { name: 'NM_CS', description: '代理商名稱' },
      { name: 'FG_TOREQ', description: '已請款旗標 (Y=已請款)' },
      { name: 'FG_RET', description: '退貨/召回旗標' },
      { name: 'DT_SHIP', description: '實際出貨日' },
    ]
  },
  {
    name: 'f_rs',
    description: '月底結帳單',
    fields: [
      { name: 'NO_RS', description: '結帳單號 (PK)' },
      { name: 'DT_APPLY', description: '結帳日期' },
      { name: 'AM_TOT', description: '結帳總金額' },
      { name: 'TY_RC', description: '收款類型' },
      { name: 'NO_GL', description: '傳票號' },
    ]
  },
  {
    name: 'i_item',
    description: '商品主檔',
    fields: [
      { name: 'ID_ITEM', description: '商品代號 (PK)' },
      { name: 'NM_ITEM / NM_SPEC', description: '品名 / 規格' },
      { name: 'NO_COLOR / NO_SIZE', description: '顏色 / 尺寸' },
      { name: 'UM', description: '單位' },
      { name: 'FG_TAX', description: '課稅別' },
      { name: 'FG_BATNO', description: '是否需批號管理' },
    ]
  },
  {
    name: 'g_cust',
    description: '客戶主檔',
    fields: [
      { name: 'ID_CUST', description: '客戶代號 (PK)' },
      { name: 'NM_C / NM_CENG', description: '中文 / 英文名稱' },
      { name: 'ID_CUSTP', description: '通路代號 (P代碼)' },
      { name: 'NN_TEL / NN_CELL', description: '電話 / 手機' },
      { name: 'AR_EMAIL', description: 'Email' },
      { name: 'FG_ACTIVE', description: '啟用狀態' },
    ]
  },
]

const pChannels = [
  { code: 'P001', name: 'J & K Resources' },
  { code: 'P002', name: 'VAN' },
  { code: 'P003', name: 'Brett / Morgan Hand' },
  { code: 'P004', name: 'gill' },
  { code: 'P005', name: 'LOVE PIECE CLUB' },
  { code: 'P006', name: 'Andrey' },
  { code: 'P007', name: '雅虎購物' },
  { code: 'P008', name: '統一 / 統一金流' },
  { code: 'P009', name: 'HappyGo' },
  { code: 'P010', name: '宅配通 / 胡涵萱' },
  { code: 'P011', name: 'EZSHIP / EZSHIP斗牛' },
  { code: 'P012', name: 'DOUBLE郵局 / 郵局' },
  { code: 'P013', name: '台灣里' },
  { code: 'P014', name: 'PAYPAL / 郵局' },
  { code: 'P015', name: '香港中國銀行' },
  { code: 'P016', name: '聯信中心 / 黃榆燕' },
  { code: 'P017', name: '余育婕 / 小高香水情趣店' },
  { code: 'P018', name: 'momo' },
  { code: 'P019', name: 'Vicki / 王云婷' },
  { code: 'P020', name: '小璇' },
  { code: 'P022', name: '現金' },
  { code: 'P023', name: '奇摩輕鬆付' },
  { code: 'P024', name: '台南小旋 / 達康凱耀' },
  { code: 'P025', name: '7-11凱耀' },
  { code: 'P026', name: '大陸支付寶' },
  { code: 'P027', name: '陳春香(大陸代理)' },
  { code: 'P028', name: 'C012825 / DB官網 / 陳婉筠' },
  { code: 'P029', name: 'DBY拍' },
  { code: 'P030', name: 'DB露天' },
  { code: 'P031', name: 'RSY拍' },
  { code: 'P032', name: 'RS露天' },
  { code: 'P033', name: '工商銀行 / 西門現金' },
  { code: 'P034', name: 'POEM / 西門刷卡' },
  { code: 'P035', name: '7-11大智通 / 7-11統一' },
  { code: 'P036', name: '九易App' },
  { code: 'P037', name: 'PChome' },
  { code: 'P038', name: 'DB復興店' },
  { code: 'P039', name: '台中現金' },
  { code: 'P040', name: '台中刷卡' },
  { code: 'P041', name: '台中便利配' },
  { code: 'P042', name: '7-11SL' },
  { code: 'P043', name: '歐付寶' },
  { code: 'P045', name: 'Shop Line / SHOPLINE' },
  { code: 'P046', name: 'MOMO / 新官網' },
  { code: 'P047', name: '超級商城' },
  { code: 'P048', name: '東區現金' },
  { code: 'P049', name: '東區刷卡' },
  { code: 'P050', name: '中和辦公室 / 官網刷卡' },
  { code: 'P051', name: '蝦皮 / 蝦皮拍賣' },
  { code: 'P052', name: '台中RS拍賣 / 台灣電力公司' },
  { code: 'P053', name: '綠界刷卡' },
  { code: 'P054', name: '香港SL' },
  { code: 'P055', name: '達博合庫' },
  { code: 'P056', name: '達博優合庫' },
  { code: 'P057', name: '玉山王外幣' },
  { code: 'P058', name: '一銀王台幣' },
  { code: 'P059', name: '合庫刷卡' },
  { code: 'P060', name: 'LINE Pay / MX信用卡 / MX積分' },
  { code: 'P061', name: 'MX金融卡 / 街口支付' },
  { code: 'P062', name: 'MX-711 / 悠遊付' },
  { code: 'P063', name: 'MX-全家' },
  { code: 'P065', name: '束胸現金 / 高雄現金' },
  { code: 'P066', name: '高雄刷卡' },
  { code: 'P067', name: '淘寶 / 淘寶賣場' },
  { code: 'P068', name: '3倍卷 / 五倍卷 / 現金卷' },
  { code: 'P069', name: '西門' },
  { code: 'P070', name: '台中' },
  { code: 'P071', name: '高雄 / 高雄束胸' },
  { code: 'P072', name: '戀愛實習生' },
  { code: 'P073', name: '酒吧現金' },
  { code: 'P074', name: 'Line pay / 官網linepay' },
]

const migrationMappings = [
  { oldTable: 'g_so', newTable: 'orders', description: '銷貨單 → 保留 order_no 自然鍵', status: '已完成' },
  { oldTable: 'g_sos', newTable: 'order_items', description: '銷貨明細，含 fifo_lot_id', status: '已完成' },
  { oldTable: 'clm_cust', newTable: 'consignments', description: '託售出貨單', status: '已完成' },
  { oldTable: 'clm_custs', newTable: 'consignment_items', description: '託售明細，含合約價格', status: '已完成' },
  { oldTable: 'f_rs', newTable: 'settlements', description: '月底結帳單，含 consignment_ids (JSONB)', status: '已完成' },
  { oldTable: 'f_rs_ars', newTable: 'settlement_items', description: '月結沖帳明細', status: '已完成' },
  { oldTable: 'f_ar', newTable: 'accounts_receivable', description: '應收帳款', status: '已完成' },
  { oldTable: 'f_gl', newTable: 'general_ledger', description: '總帳分錄', status: '已完成' },
  { oldTable: 'i_item', newTable: 'items', description: '商品主檔，新增 color/size/lifecycle_status', status: '已完成' },
  { oldTable: 'i_mm / i_tran', newTable: 'inventory + inventory_lots', description: 'FIFO 先進先出批次', status: '已完成' },
  { oldTable: 'g_cust', newTable: 'customers', description: '客戶，含 customer_type 區分通路', status: '已完成' },
  { oldTable: 'pub_emp', newTable: '(待實作)', description: '人員模組', status: '待實作' },
  { oldTable: 'pub_dept', newTable: '(待實作)', description: '部門模組', status: '待實作' },
  { oldTable: 'p_po', newTable: '(待實作)', description: '採購模組', status: '待實作' },
]

const filteredChannels = computed(() => {
  const search = channelSearch.value.toLowerCase()
  return pChannels.filter(c =>
    c.code.toLowerCase().includes(search) ||
    c.name.toLowerCase().includes(search)
  )
})

function getStatusClass(status) {
  switch (status) {
    case '已完成': return 'badge-success'
    case '待實作': return 'badge-warning'
    default: return 'badge-muted'
  }
}
</script>

<style scoped>
.table-classification {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin-top: 1rem;
}

.category-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1.25rem;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  cursor: pointer;
  transition: var(--transition-smooth);
}

.category-item:hover {
  background: rgba(99, 102, 241, 0.1);
  border-color: var(--color-primary);
}

.category-item.active {
  background: rgba(99, 102, 241, 0.2);
  border-color: var(--color-primary);
  box-shadow: 0 0 15px var(--color-primary-glow);
}

.category-prefix {
  font-family: monospace;
  font-weight: 700;
  color: var(--color-primary);
  font-size: 1.1rem;
}

.category-count {
  font-size: 0.85rem;
  color: var(--text-muted);
}

.category-desc {
  font-size: 0.8rem;
  color: var(--text-muted);
}

.table-selector {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.table-tab {
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  color: var(--text-muted);
  font-size: 0.85rem;
  cursor: pointer;
  transition: var(--transition-smooth);
}

.table-tab:hover {
  background: rgba(99, 102, 241, 0.1);
  color: var(--text-main);
}

.table-tab.active {
  background: var(--color-primary);
  color: #fff;
  border-color: var(--color-primary);
}

.table-structure h3 {
  font-size: 1rem;
  color: var(--color-primary);
  margin-bottom: 1rem;
}

.field-name {
  font-family: monospace;
  color: var(--color-success);
}

.search-box {
  margin-bottom: 1rem;
}

.search-input {
  width: 100%;
  padding: 0.75rem 1rem;
  background: rgba(31, 41, 55, 0.5);
  border: 1px solid var(--border-glass);
  border-radius: var(--radius-input);
  color: #fff;
  font-size: 0.95rem;
}

.search-input:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px var(--color-primary-glow);
}

.channel-list {
  max-height: 400px;
  overflow-y: auto;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.5rem;
}

.channel-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0.75rem;
  background: rgba(255, 255, 255, 0.02);
  border-radius: 8px;
  font-size: 0.9rem;
}

.channel-code {
  font-family: monospace;
  font-weight: 600;
  color: var(--color-primary);
  min-width: 50px;
}

.channel-name {
  color: var(--text-main);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.phase-list {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.5rem;
  margin-top: 1rem;
}

.phase-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 1.25rem;
  border-radius: var(--radius-card);
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--border-glass);
}

.phase-a {
  border-left: 4px solid var(--color-primary);
}

.phase-b {
  border-left: 4px solid var(--color-success);
}

.phase-c {
  border-left: 4px solid var(--color-warning);
}

.phase-d {
  border-left: 4px solid var(--color-danger);
}

.phase-label {
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--text-muted);
}

.phase-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: #fff;
}

.phase-desc {
  font-size: 0.85rem;
  color: var(--text-muted);
}

@media (max-width: 1200px) {
  .phase-list {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .phase-list {
    grid-template-columns: 1fr;
  }
}
</style>
