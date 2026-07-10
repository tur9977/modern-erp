<template>
  <div class="animate-fade-in">
    <h1>直營銷貨單 (g_so)</h1>
    <p class="subtitle">直營門市與線上通路銷售，即時扣減總倉可用在庫並進行 FIFO 成本結轉</p>

    <div class="grid-cols-2">
      <!-- Create Order Form -->
      <div class="glass-card">
        <h2>建立銷貨單</h2>
                <form @submit.prevent="submitOrder" class="order-form-layout" style="display: grid; grid-template-columns: 2.5fr 1fr; gap: 1.5rem; align-items: start;">
          
          <!-- 左側主區塊 (Main Content) -->
          <div class="form-main" style="display: flex; flex-direction: column; gap: 1rem;">
            
            <!-- 區塊 A：客戶與基本資訊 -->
            <div style="border: 1px solid var(--border-glass); border-radius: var(--radius-card); padding: 1.25rem;">
              <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 1rem;">
                <h3 style="font-size: 1.05rem; margin: 0; color: var(--primary-color);">區塊 A: 客戶與運送資訊</h3>
                <button type="button" class="btn-link" @click="openQuickAdd('customer')">+ 新增會員</button>
              </div>

              <div class="grid-cols-2">
                <!-- 客戶搜尋 -->
                <div class="form-group" style="margin-bottom: 0; position: relative;">
                  <label>搜尋客戶 (代號/電話/姓名)</label>
                  <input
                    type="text"
                    v-model="customerSearchQuery"
                    placeholder="輸入電話、姓名或代號..."
                    @input="onCustomerSearchInput"
                    @focus="showCustomerSuggestions = true"
                    ref="customerSearchInput"
                  />
                  <!-- Auto-suggest customer list -->
                  <ul v-if="showCustomerSuggestions && filteredCustomers.length > 0" class="suggestions-dropdown">
                    <li v-for="c in filteredCustomers" :key="c.id" @click="selectCustomer(c)">
                      <span class="customer-name">{{ c.name }}</span>
                      <span class="customer-code">{{ c.code }}</span>
                      <span class="customer-phone">{{ c.phone || c.mobile || '無電話' }}</span>
                    </li>
                  </ul>
                </div>

                <!-- 客戶單號 -->
                <div class="form-group" style="margin-bottom: 0;">
                  <label>客戶單號 (例: 蝦皮訂單號)</label>
                  <input type="text" v-model="customerOrderNo" placeholder="2607096KCK34AD" />
                </div>
              </div>

              <!-- 已選客戶資訊 -->
              <div v-if="selectedCustomer" class="selected-customer-card animate-fade-in" style="margin-top: 1rem;">
                <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 0.5rem;">
                  <div><strong>姓名/聯絡人:</strong> {{ selectedCustomer.name }}</div>
                  <div><strong>客戶代號:</strong> {{ selectedCustomer.code }}</div>
                  <div><strong>電話:</strong> {{ selectedCustomer.phone || selectedCustomer.mobile || '-' }}</div>
                  <div><strong>Email:</strong> {{ selectedCustomer.email || '-' }}</div>
                </div>
                <button type="button" class="btn-link" style="margin-top: 0.5rem; font-size: 0.75rem;" @click="clearCustomerSelection">清除選擇</button>
              </div>

              <div class="grid-cols-2" style="margin-top: 1rem;">
                <div class="form-group" style="margin-bottom: 0;">
                  <label>取貨方式</label>
                  <select v-model="deliveryMethod">
                    <option value="宅配">宅配</option>
                    <option value="超商取貨">超商取貨</option>
                    <option value="自取">自取</option>
                  </select>
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                  <label>送貨地址 (預設帶入客戶地址)</label>
                  <input type="text" :value="selectedCustomer ? selectedCustomer.delivery_address : ''" placeholder="全家 竹山桶頭店 等..." />
                </div>
              </div>
            </div>

            <!-- 區塊 B：商品明細 -->
            <div style="border: 1px solid var(--border-glass); border-radius: var(--radius-card); padding: 1.25rem;">
              <h3 style="font-size: 1.05rem; margin-bottom: 1rem; color: var(--primary-color);">區塊 B: 銷貨明細 (DataGrid)</h3>

              <div style="display: grid; grid-template-columns: 2fr 1fr 1.2fr; gap: 1rem; margin-bottom: 1rem; align-items: flex-end;">
                <!-- 貨號速查 -->
                <div class="form-group" style="margin-bottom: 0; position: relative;">
                  <label>產品代號/品名速查</label>
                  <input
                    type="text"
                    v-model="itemSearchQuery"
                    placeholder="輸入貨號或品名 (例如: T0041003)..."
                    @input="onItemSearchInput"
                    @focus="showItemSuggestions = true"
                    ref="searchInput"
                  />
                  <!-- Auto-suggest -->
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
                  <input type="number" v-model="qty" min="1" />
                </div>
                <button type="button" class="btn btn-secondary" @click="addItem">加入明細</button>
              </div>

              <div v-if="selectedItemInfo" class="selected-item-preview animate-fade-in">
                已選: <strong>[{{ selectedItemInfo.sku }}] {{ selectedItemInfo.name }}</strong> |
                {{ selectedItemInfo.color || '無' }}/{{ selectedItemInfo.size || '無' }} |
                庫存: 100 | 單價: <span class="price-highlight">${{ selectedItemInfo.retail_price }}</span>
              </div>

              <!-- Item Table -->
              <table v-if="itemsList.length > 0" class="modern-datagrid">
                <thead>
                  <tr>
                    <th style="width: 50px;">順序</th>
                    <th>產品代號/品名</th>
                    <th>顏色/尺寸</th>
                    <th>倉庫</th>
                    <th style="text-align:right;">出貨數量</th>
                    <th style="text-align:right;">單價</th>
                    <th style="text-align:right;">小計</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(item, index) in itemsList" :key="index">
                    <td style="text-align:center;">{{ index + 1 }}</td>
                    <td>
                      <div style="font-weight:600;">{{ item.sku }}</div>
                      <div style="font-size:0.8rem; color:var(--text-muted);">{{ item.name }}</div>
                    </td>
                    <td>{{ item.color || '-' }} / {{ item.size || '-' }}</td>
                    <td>DOUBLE總倉</td>
                    <td style="text-align:right;">{{ item.qty }} 件</td>
                    <td style="text-align:right;">${{ item.price }}</td>
                    <td style="text-align:right; font-weight:600;">${{ item.qty * item.price }}</td>
                    <td style="text-align:center;">
                      <button type="button" @click="removeItem(index)" style="background:none; border:none; color: var(--color-danger); cursor:pointer;">✕</button>
                    </td>
                  </tr>
                </tbody>
              </table>
              <div v-else style="text-align:center; color: var(--text-muted); padding: 2rem; border: 1px dashed var(--border-color); border-radius: 8px;">
                尚未加入任何商品
              </div>
            </div>
          </div>

          <!-- 右側側邊欄 (Sidebar Settings) -->
          <div class="form-sidebar" style="display: flex; flex-direction: column; gap: 1rem;">
            
            <!-- 區塊 C: 單據設定 -->
            <div style="border: 1px solid var(--border-glass); border-radius: var(--radius-card); padding: 1.25rem; background: var(--bg-card);">
              <h3 style="font-size: 0.95rem; margin-top: 0; margin-bottom: 1rem; color: var(--text-muted); border-bottom: 1px solid var(--border-light); padding-bottom: 0.5rem;">區塊 C: 單據設定</h3>
              
              <div class="form-group">
                <label>銷貨單號</label>
                <input type="text" v-model="orderNo" disabled style="background: var(--bg-main);" />
              </div>
              <div class="grid-cols-2">
                <div class="form-group">
                  <label>銷貨日期</label>
                  <input type="date" v-model="salesDate" />
                </div>
                <div class="form-group">
                  <label>立帳日</label>
                  <input type="date" v-model="accountingDate" />
                </div>
              </div>
              <div class="grid-cols-2">
                <div class="form-group">
                  <label>員工代號</label>
                  <input type="text" v-model="employeeId" />
                </div>
                <div class="form-group">
                  <label>部門</label>
                  <input type="text" v-model="departmentId" placeholder="業務部" />
                </div>
              </div>
            </div>

            <!-- 區塊 D: 帳款與專案 -->
            <div style="border: 1px solid var(--border-glass); border-radius: var(--radius-card); padding: 1.25rem; background: var(--bg-card);">
              <h3 style="font-size: 0.95rem; margin-top: 0; margin-bottom: 1rem; color: var(--text-muted); border-bottom: 1px solid var(--border-light); padding-bottom: 0.5rem;">區塊 D: 帳款與專案</h3>
              
              <div class="form-group">
                <label>計價方式</label>
                <select v-model="pricingMethod">
                  <option value="零售價">零售價</option>
                  <option value="批發價">批發價</option>
                </select>
              </div>
              <div class="grid-cols-2">
                <div class="form-group">
                  <label>專案代號</label>
                  <input type="text" v-model="projectId" placeholder="例: 蝦皮" />
                </div>
                <div class="form-group">
                  <label>請款對象</label>
                  <select v-model="collectionTargetId">
                    <option value="" disabled>請選擇</option>
                    <option v-for="ct in collectionTargets" :key="ct.id" :value="ct.id">
                      {{ ct.name }}
                    </option>
                  </select>
                </div>
              </div>
              <div class="form-group" style="margin-bottom: 0;">
                <label>銷售渠道</label>
                <select v-model="channelId">
                  <option value="" disabled>請選擇</option>
                  <option v-for="ch in channels" :key="ch.id" :value="ch.id">{{ ch.name }}</option>
                </select>
              </div>
            </div>

            <!-- 區塊 E: 總計與提交 -->
            <div style="border: 1px solid var(--border-glass); border-radius: var(--radius-card); padding: 1.25rem; background: var(--bg-card);">
              
              <div class="form-group">
                <label>備註</label>
                <textarea v-model="remarks" rows="2" placeholder="單據備註..."></textarea>
              </div>

              <div style="background: rgba(139, 105, 20, 0.05); padding: 1rem; border-radius: 6px; margin-bottom: 1.5rem;">
                <div style="display:flex; justify-content:space-between; margin-bottom: 0.5rem;">
                  <span style="color:var(--text-muted);">總件數</span>
                  <span style="font-weight:600;">{{ itemsList.reduce((sum, item) => sum + item.qty, 0) }} 件</span>
                </div>
                <div style="display:flex; justify-content:space-between; border-top: 1px solid rgba(139, 105, 20, 0.2); padding-top: 0.5rem;">
                  <span style="color:var(--text-muted);">應收總計 NTD</span>
                  <span style="font-size: 1.5rem; font-weight: 700; color: var(--primary-color);">${{ totalAmount.toFixed(2) }}</span>
                </div>
              </div>

              <button type="submit" class="btn btn-primary" style="width: 100%; padding: 0.75rem; font-size: 1.05rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:0.5rem; vertical-align:middle;"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
                儲存銷貨單 (Draft)
              </button>
            </div>
          </div>
        </form>
      </div>

      <!-- Past Orders List -->
      <div class="glass-card">
        <h2>銷貨單歷史紀錄</h2>
        <div style="max-height: 500px; overflow-y: auto;">
          <table>
            <thead>
              <tr>
                <th>單號</th>
                <th>日期</th>
                <th>通路</th>
                <th>客戶</th>
                <th>總額</th>
                <th>狀態</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="order in ordersHistory" :key="order.id">
                <td>{{ order.order_no }}</td>
                <td>{{ order.order_date }}</td>
                <td>{{ order.channel_name || '-' }}</td>
                <td>{{ order.customer_name || '-' }}</td>
                <td>${{ order.total }}</td>
                <td style="white-space: nowrap;">
                <span class="badge" :class="getStatusClass(order.status)" style="margin-right: 0.75rem;">{{ order.status }}</span>
                <span class="btn-separator" v-if="order.status === 'DRAFT' || order.status === 'SHIPPED'">|</span>
                <button v-if="order.status === 'DRAFT'" type="button" class="btn-action btn-ship" @click="shipOrder(order.id)">[出貨]</button>
                <button v-if="order.status === 'DRAFT'" type="button" class="btn-action btn-cancel" @click="cancelOrder(order.id)">[取消]</button>
                <button v-if="order.status === 'SHIPPED'" type="button" class="btn-action btn-return" @click="returnOrder(order.id)">[退貨]</button>
              </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Quick Add Modal (Channel / Payment Method / Collection Target) -->
    <div class="modal-backdrop" v-if="quickAddType && quickAddType !== 'customer'">
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

    <!-- Quick Add Customer Modal -->
    <div class="modal-backdrop" v-if="quickAddType === 'customer'">
      <div class="modal-card glass-card" style="max-width: 550px;">
        <h3>新增會員資料</h3>
        <div class="modal-form" style="max-height: 60vh; overflow-y: auto;">
          <div class="grid-cols-2">
            <div class="form-group">
              <label>會員代號 *</label>
              <input type="text" v-model="customerForm.code" readonly placeholder="系統自動產生" class="code-readonly" />
            </div>
            <div class="form-group">
              <label>會員類型 *</label>
              <select v-model="customerForm.type" required>
                <option value="RETAIL">一般會員</option>
                <option value="AGENT">代理商</option>
                <option value="CHANNEL">通路商</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>姓名/名稱 *</label>
            <input type="text" v-model="customerForm.name" required placeholder="會員姓名或公司名稱" />
          </div>
          <div class="grid-cols-2">
            <div class="form-group">
              <label>電話</label>
              <input type="text" v-model="customerForm.phone" placeholder="例: 0912-345-678" />
            </div>
            <div class="form-group">
              <label>手機</label>
              <input type="text" v-model="customerForm.mobile" placeholder="例: 0988-123-456" />
            </div>
          </div>
          <div class="form-group">
            <label>Email</label>
            <input type="email" v-model="customerForm.email" placeholder="例: example@email.com" />
          </div>
          <div class="form-group">
            <label>送貨地址</label>
            <input type="text" v-model="customerForm.delivery_address" placeholder="完整送貨地址" />
          </div>
          <div class="grid-cols-2">
            <div class="form-group">
              <label>統一編號</label>
              <input type="text" v-model="customerForm.tax_id" placeholder="公司用：統一編號" />
            </div>
            <div class="form-group">
              <label>隸屬通路</label>
              <select v-model="customerForm.channel_id">
                <option value="">無</option>
                <option v-for="ch in channels" :key="ch.id" :value="ch.id">
                  {{ ch.name }} ({{ ch.code }})
                </option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>備註</label>
            <textarea v-model="customerForm.note" rows="2" placeholder="其他備註資訊..."></textarea>
          </div>
        </div>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="closeQuickAdd">取消</button>
          <button class="btn btn-primary" @click="submitCustomer">儲存並選擇此會員</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Orders',
  data() {
    return {
      orderNo: 'SO-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '001',
      salesDate: new Date().toISOString().slice(0, 10),
      accountingDate: new Date().toISOString().slice(0, 10),
      employeeId: 'NEAL',
      departmentId: '',
      customerOrderNo: '',
      deliveryMethod: '宅配',
      pricingMethod: '零售價',
      projectId: '',
      remarks: '',
      channelId: '',
      paymentMethodId: '',
      collectionTargetId: '',

      // Customer search
      customerSearchQuery: '',
      showCustomerSuggestions: false,
      filteredCustomers: [],
      selectedCustomer: null,

      // Auto-suggest product search
      itemSearchQuery: '',
      showItemSuggestions: false,
      filteredItems: [],
      selectedItemInfo: null,
      qty: 1,

      itemsList: [],
      ordersHistory: [],

      // Dynamic dropdowns
      channels: [],
      paymentMethods: [],
      collectionTargets: [],
      customers: [],
      items: [],

      // Quick Add Modals
      quickAddType: null,
      quickAddForm: {
        code: '',
        name: '',
        type: 'direct'
      },

      // Customer form
      customerForm: {
        tenant_id: 1,
        code: '',
        name: '',
        type: 'RETAIL',
        phone: '',
        mobile: '',
        email: '',
        delivery_address: '',
        tax_id: '',
        channel_id: '',
        note: ''
      }
    }
  },
  computed: {
    quickAddTitle() {
      if (this.quickAddType === 'channel') return '銷售渠道'
      if (this.quickAddType === 'paymentMethod') return '付款方式'
      if (this.quickAddType === 'collectionTarget') return '請款對象'
      if (this.quickAddType === 'customer') return '會員資料'
      return ''
    },
    subtotalAmount() {
      return this.itemsList.reduce((sum, item) => sum + (item.qty * item.price), 0)
    },
    taxAmount() {
      return this.subtotalAmount * 0.05
    },
    totalAmount() {
      return this.subtotalAmount + this.taxAmount
    }
  },
  mounted() {
    this.fetchMasterData()
    this.fetchOrdersHistory()

    // Close suggestions dropdown when clicking outside
    document.addEventListener('click', this.handleClickOutside)
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleClickOutside)
  },
  methods: {
    async fetchMasterData() {
      try {
        const [resCh, resPm, resCt, resIt, resCust] = await Promise.all([
          this.$api.get('/channels/'),
          this.$api.get('/payment-methods/'),
          this.$api.get('/collection-targets/'),
          this.$api.get('/items/'),
          this.$api.get('/customers/')
        ])
        this.channels = resCh.data
        if (this.channels.length > 0) this.channelId = this.channels[0].id
        this.paymentMethods = resPm.data
        if (this.paymentMethods.length > 0) this.paymentMethodId = this.paymentMethods[0].id
        this.collectionTargets = resCt.data
        if (this.collectionTargets.length > 0) this.collectionTargetId = this.collectionTargets[0].id
        this.items = resIt.data
        this.customers = resCust.data
      } catch (err) {
        console.error('Failed to load master data:', err)
      }
    },
    async fetchOrdersHistory() {
      try {
        const res = await this.$api.get('/orders/')
        const orders = res.data
        this.ordersHistory = orders.map(o => ({
          ...o,
          channel_name: this.channels.find(c => c.id === o.channel_id)?.name || '',
          customer_name: o.customer_name || this.customers.find(c => c.id === o.customer_id)?.name || ''
        }))
      } catch (err) {
        console.error('Failed to load orders history:', err)
      }
    },
    getStatusClass(status) {
      if (status === 'DRAFT') return 'badge-warning'
      if (status === 'SHIPPED') return 'badge-success'
      if (status === 'CANCELLED') return 'badge-danger'
      if (status === 'RETURNED') return 'badge-secondary'
      return 'badge-default'
    },
    async shipOrder(id) {
      if (!confirm('確認出貨？DRAFT→SHIPPED，將扣除 FIFO 庫存')) return
      try {
        await this.$api.post(`/orders/${id}/ship`)
        alert('出貨成功！')
        this.fetchOrdersHistory()
      } catch (err) {
        alert('出貨失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async cancelOrder(id) {
      if (!confirm('確認取消？DRAFT→CANCELLED')) return
      try {
        await this.$api.post(`/orders/${id}/cancel`)
        alert('取消成功！')
        this.fetchOrdersHistory()
      } catch (err) {
        alert('取消失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async returnOrder(id) {
      if (!confirm('確認退貨？SHIPPED→RETURNED，將退回 FIFO 庫存')) return
      try {
        await this.$api.post(`/orders/${id}/return`)
        alert('退貨成功！')
        this.fetchOrdersHistory()
      } catch (err) {
        alert('退貨失敗: ' + (err.response?.data?.detail || err.message))
      }
    },

    // Customer search methods
    onCustomerSearchInput() {
      if (!this.customerSearchQuery.trim()) {
        this.filteredCustomers = []
        return
      }
      const q = this.customerSearchQuery.toLowerCase()
      this.filteredCustomers = this.customers.filter(c =>
        (c.name && c.name.toLowerCase().includes(q)) ||
        (c.code && c.code.toLowerCase().includes(q)) ||
        (c.phone && c.phone.includes(q)) ||
        (c.mobile && c.mobile.includes(q)) ||
        (c.email && c.email.toLowerCase().includes(q))
      ).slice(0, 20)
    },
    selectCustomer(customer) {
      this.selectedCustomer = customer
      this.customerSearchQuery = ''
      this.showCustomerSuggestions = false
      this.filteredCustomers = []
    },
    clearCustomerSelection() {
      this.selectedCustomer = null
    },

    // Item search methods
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
      if (this.$refs.customerSearchInput && !this.$refs.customerSearchInput.contains(e.target)) {
        this.showCustomerSuggestions = false
      }
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
    },
    removeItem(index) {
      this.itemsList.splice(index, 1)
    },

    // Quick Add
    openQuickAdd(type) {
      this.quickAddType = type
      if (type === 'channel') {
        this.quickAddForm = { tenant_id: 1, code: '', name: '', type: 'direct' }
      } else if (type === 'paymentMethod') {
        this.quickAddForm = { tenant_id: 1, code: '', name: '', type: 'CASH' }
      } else if (type === 'collectionTarget') {
        this.quickAddForm = { tenant_id: 1, code: '', name: '', type: 'DIRECT' }
      } else if (type === 'customer') {
        // Generate a new customer code
        const maxCode = this.customers.reduce((max, c) => {
          const num = parseInt(c.code.replace(/\D/g, '') || '0')
          return num > max ? num : max
        }, 0)
        this.customerForm = {
          tenant_id: 1,
          code: 'C' + String(maxCode + 1).padStart(5, '0'),
          name: '',
          type: 'RETAIL',
          phone: '',
          mobile: '',
          email: '',
          delivery_address: '',
          invoice_address: '',
          payment_method: '信用卡',
          billing_target: '',
          tax_id: '',
          channel_id: '',
          note: ''
        }
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
    generateCustomerCode(type) {
      // 過濾同類型現有代碼
      const prefix = (type === 'RETAIL') ? 'M' : 'P'
      const digits = (type === 'RETAIL') ? 5 : 4
      const existing = this.customers
        .filter(c => c.code && c.code.startsWith(prefix))
        .map(c => parseInt(c.code.slice(prefix.length)) || 0)
      const maxSeq = existing.length > 0 ? Math.max(...existing) : 0
      return prefix + String(maxSeq + 1).padStart(digits, '0')
    },
    async submitCustomer() {
      // 自動產生會員代號
      if (!this.customerForm.code) {
        this.customerForm.code = this.generateCustomerCode(this.customerForm.type || 'RETAIL')
      }
      if (!this.customerForm.name) {
        alert('請填寫會員姓名')
        return
      }
      try {
        // 把空字串轉 null，避免 API int parsing 錯誤
        const payload = { ...this.customerForm }
        for (const key of Object.keys(payload)) {
          if (payload[key] === '') payload[key] = null
        }
        payload.channel_id = payload.channel_id ? parseInt(payload.channel_id) : null
        const res = await this.$api.post('/customers/', payload)
        const data = res.data
        alert('會員新增成功！')
        await this.fetchMasterData()
        this.selectCustomer(data)
        this.closeQuickAdd()
      } catch (err) {
        alert('新增失敗: ' + (err.response?.data?.detail || err.message))
      }
    },
    async submitOrder() {
      if (this.itemsList.length === 0) {
        alert('請加入商品明細')
        return
      }

      const payload = {
        tenant_id: 1,
        order_date: this.salesDate,
        accounting_date: this.accountingDate || null,
        channel_id: parseInt(this.channelId),
        collection_target_id: parseInt(this.collectionTargetId),
        payment_method_id: parseInt(this.paymentMethodId),
        employee_id: this.employeeId || null,
        department_id: this.departmentId || null,
        project_id: this.projectId || null,
        remarks: this.remarks || null,
        customer_id: this.selectedCustomer ? this.selectedCustomer.id : null,
        customer_name: this.selectedCustomer ? this.selectedCustomer.name : null,
        customer_phone: this.selectedCustomer ? (this.selectedCustomer.phone || this.selectedCustomer.mobile) : null,
        customer_address: this.selectedCustomer ? this.selectedCustomer.delivery_address : null,
        items: this.itemsList.map(item => ({
          item_id: item.item_id,
          qty: parseFloat(item.qty),
          unit_price: parseFloat(item.price)
        }))
      }

      try {
        const res = await this.$api.post('/orders/', payload)
        const result = res.data
        alert('銷貨過帳成功！已扣除總倉 FIFO 庫存與認列銷貨收入。')
        this.itemsList = []
        this.selectedCustomer = null
        // orderNo 由後端自動產生，前端不用管
        this.fetchOrdersHistory()
      } catch (err) {
        alert('過帳失敗: ' + (err.response?.data?.detail || err.message))
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

/* Customer suggestions */
.customer-name {
  font-weight: 600;
  color: var(--text-main);
}
.customer-code {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-left: 0.5rem;
}
.customer-phone {
  font-size: 0.8rem;
  color: var(--color-primary);
  margin-left: auto;
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
  margin-left: auto;
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

/* Selected customer card */
.selected-customer-card {
  background: rgba(16, 185, 129, 0.1);
  border: 1px solid rgba(16, 185, 129, 0.3);
  padding: 0.75rem 1rem;
  border-radius: 8px;
  margin-top: 0.75rem;
  font-size: 0.85rem;
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

/* Status legend */
.status-legend {
  display: flex;
  gap: 1.5rem;
  margin-top: 0.75rem;
  padding: 0.6rem 1rem;
  background: rgba(255,255,255,0.03);
  border-radius: var(--radius-input);
  font-size: 0.8rem;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  color: var(--text-muted);
}
.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.legend-dot.draft { background: #f59e0b; }
.legend-dot.shipped { background: #10b981; }

/* Action buttons */
.btn-action {
  background: none;
  border: 1px solid;
  border-radius: 4px;
  padding: 0.15rem 0.4rem;
  font-size: 0.75rem;
  cursor: pointer;
  margin-left: 0.25rem;
}
.btn-separator {
  color: var(--text-muted);
  font-size: 0.75rem;
  margin: 0 0.25rem;
}
.btn-ship {
  border-color: var(--color-primary);
  color: var(--color-primary);
}
.btn-ship:hover {
  background: var(--color-primary);
  color: #fff;
}
.btn-cancel {
  border-color: var(--color-danger);
  color: var(--color-danger);
}
.btn-cancel:hover {
  background: var(--color-danger);
  color: #fff;
}
.btn-return {
  border-color: #8b5cf6;
  color: #8b5cf6;
}
.btn-return:hover {
  background: #8b5cf6;
  color: #fff;
}

/* Badge variants */
.badge-warning {
  background: rgba(245, 158, 11, 0.15);
  color: #f59e0b;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}
.badge-secondary {
  background: rgba(107, 114, 128, 0.15);
  color: #9ca3af;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}
.badge-default {
  background: rgba(255,255,255,0.05);
  color: var(--text-muted);
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}
.code-readonly {
  background: var(--bg-tertiary, #e5e7eb) !important;
  color: var(--text-muted, #6b7280);
  cursor: not-allowed;
}
</style>
