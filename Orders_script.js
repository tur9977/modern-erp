<script>
import { supabase } from '../supabase'

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

      customerSearchQuery: '',
      showCustomerSuggestions: false,
      filteredCustomers: [],
      selectedCustomer: null,

      itemSearchQuery: '',
      showItemSuggestions: false,
      filteredItems: [],
      selectedItemInfo: null,
      qty: 1,

      itemsList: [],
      ordersHistory: [],

      channels: [],
      paymentMethods: [],
      collectionTargets: [],
      customers: [],
      items: [],

      quickAddType: null,
      quickAddForm: {
        code: '',
        name: '',
        type: 'direct'
      },

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
  async mounted() {
    await this.fetchMasterData()
    await this.fetchOrdersHistory()
    document.addEventListener('click', this.handleClickOutside)
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleClickOutside)
  },
  methods: {
    async fetchMasterData() {
      try {
        const [
          { data: channels },
          { data: paymentMethods },
          { data: collectionTargets },
          { data: items },
          { data: customers }
        ] = await Promise.all([
          supabase.from('erp_channels').select('*'),
          supabase.from('erp_payment_methods').select('*'),
          supabase.from('erp_collection_targets').select('*'),
          supabase.from('erp_items').select('*'),
          supabase.from('erp_customers').select('*')
        ])

        this.channels = channels || []
        if (this.channels.length > 0) this.channelId = this.channels[0].id
        
        this.paymentMethods = paymentMethods || []
        if (this.paymentMethods.length > 0) this.paymentMethodId = this.paymentMethods[0].id
        
        this.collectionTargets = collectionTargets || []
        if (this.collectionTargets.length > 0) this.collectionTargetId = this.collectionTargets[0].id
        
        this.items = items || []
        this.customers = customers || []
      } catch (err) {
        console.error('Failed to load master data:', err)
      }
    },
    async fetchOrdersHistory() {
      try {
        const { data: orders, error } = await supabase.from('erp_orders').select('*').order('created_at', { ascending: false })
        if (error) throw error
        this.ordersHistory = (orders || []).map(o => ({
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
        const { error } = await supabase.from('erp_orders').update({ status: 'SHIPPED' }).eq('id', id)
        if (error) throw error
        alert('出貨成功！')
        this.fetchOrdersHistory()
      } catch (err) {
        alert('出貨失敗: ' + err.message)
      }
    },
    async cancelOrder(id) {
      if (!confirm('確認取消？DRAFT→CANCELLED')) return
      try {
        const { error } = await supabase.from('erp_orders').update({ status: 'CANCELLED' }).eq('id', id)
        if (error) throw error
        alert('取消成功！')
        this.fetchOrdersHistory()
      } catch (err) {
        alert('取消失敗: ' + err.message)
      }
    },
    async returnOrder(id) {
      if (!confirm('確認退貨？SHIPPED→RETURNED，將退回 FIFO 庫存')) return
      try {
        const { error } = await supabase.from('erp_orders').update({ status: 'RETURNED' }).eq('id', id)
        if (error) throw error
        alert('退貨成功！')
        this.fetchOrdersHistory()
      } catch (err) {
        alert('退貨失敗: ' + err.message)
      }
    },

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

    openQuickAdd(type) {
      this.quickAddType = type
      if (type === 'channel') {
        this.quickAddForm = { tenant_id: 1, code: '', name: '', type: 'direct' }
      } else if (type === 'paymentMethod') {
        this.quickAddForm = { tenant_id: 1, code: '', name: '', type: 'CASH' }
      } else if (type === 'collectionTarget') {
        this.quickAddForm = { tenant_id: 1, code: '', name: '', type: 'DIRECT' }
      } else if (type === 'customer') {
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
      let table = ''
      if (this.quickAddType === 'channel') table = 'erp_channels'
      if (this.quickAddType === 'paymentMethod') table = 'erp_payment_methods'
      if (this.quickAddType === 'collectionTarget') table = 'erp_collection_targets'

      try {
        const { data, error } = await supabase.from(table).insert([this.quickAddForm]).select()
        if (error) throw error
        
        alert('快速新增成功！')
        await this.fetchMasterData()

        if (data && data.length > 0) {
          if (this.quickAddType === 'channel') this.channelId = data[0].id
          if (this.quickAddType === 'paymentMethod') this.paymentMethodId = data[0].id
          if (this.quickAddType === 'collectionTarget') this.collectionTargetId = data[0].id
        }

        this.closeQuickAdd()
      } catch (err) {
        alert('新增失敗: ' + err.message)
      }
    },
    generateCustomerCode(type) {
      const prefix = (type === 'RETAIL') ? 'M' : 'P'
      const digits = (type === 'RETAIL') ? 5 : 4
      const existing = this.customers
        .filter(c => c.code && c.code.startsWith(prefix))
        .map(c => parseInt(c.code.slice(prefix.length)) || 0)
      const maxSeq = existing.length > 0 ? Math.max(...existing) : 0
      return prefix + String(maxSeq + 1).padStart(digits, '0')
    },
    async submitCustomer() {
      if (!this.customerForm.code) {
        this.customerForm.code = this.generateCustomerCode(this.customerForm.type || 'RETAIL')
      }
      if (!this.customerForm.name) {
        alert('請填寫會員姓名')
        return
      }
      try {
        const payload = { ...this.customerForm }
        for (const key of Object.keys(payload)) {
          if (payload[key] === '') payload[key] = null
        }
        payload.channel_id = payload.channel_id ? parseInt(payload.channel_id) : null
        
        const { data, error } = await supabase.from('erp_customers').insert([payload]).select()
        if (error) throw error

        alert('會員新增成功！')
        await this.fetchMasterData()
        if (data && data.length > 0) this.selectCustomer(data[0])
        this.closeQuickAdd()
      } catch (err) {
        alert('新增失敗: ' + err.message)
      }
    },
    async submitOrder() {
      if (this.itemsList.length === 0) {
        alert('請加入商品明細')
        return
      }

      try {
        // 1. Insert Order
        const orderPayload = {
          tenant_id: 1,
          order_no: 'SO-' + new Date().getTime(), // Generate a unique order_no
          type: 'DIRECT_SALE',
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
          subtotal: this.subtotalAmount,
          tax: this.taxAmount,
          total: this.totalAmount,
          status: 'DRAFT'
        }

        const { data: orderData, error: orderError } = await supabase.from('erp_orders').insert([orderPayload]).select()
        if (orderError) throw orderError
        
        const orderId = orderData[0].id

        // 2. Insert Order Items
        const orderItemsPayload = this.itemsList.map(item => ({
          order_id: orderId,
          item_id: item.item_id,
          item_code: item.sku,
          item_name: item.name,
          qty: parseFloat(item.qty),
          unit_price: parseFloat(item.price),
          subtotal: parseFloat(item.qty) * parseFloat(item.price)
        }))

        const { error: itemsError } = await supabase.from('erp_order_items').insert(orderItemsPayload)
        if (itemsError) throw itemsError

        alert('銷貨儲存成功！(草稿)')
        this.itemsList = []
        this.selectedCustomer = null
        this.fetchOrdersHistory()
      } catch (err) {
        alert('過帳失敗: ' + err.message)
      }
    }
  }
}
</script>
