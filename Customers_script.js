<script>
import { supabase } from '../supabase'

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
        const { data, error } = await supabase.from('erp_customers').select('*').order('created_at', { ascending: false })
        if (error) throw error
        this.customers = data || []
      } catch (err) {
        console.error('Failed to load customers:', err)
      }
    },
    async fetchChannels() {
      try {
        const { data, error } = await supabase.from('erp_channels').select('*')
        if (error) throw error
        this.channels = data || []
      } catch (err) {
        console.error('Failed to load channels:', err)
      }
    },
    async fetchTiers() {
      try {
        const { data, error } = await supabase.from('erp_member_tiers').select('*')
        if (error) throw error
        this.tiers = data || []
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
      if (!this.isEditing) {
        this.generateCode()
      }
    },
    generateCode() {
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
      
      const payload = { ...this.form }
      for (const key of Object.keys(payload)) {
        if (payload[key] === '') payload[key] = null
      }
      
      try {
        if (this.isEditing) {
          const { error } = await supabase.from('erp_customers').update(payload).eq('id', payload.id)
          if (error) throw error
          alert('更新成功！')
        } else {
          const { error } = await supabase.from('erp_customers').insert([payload])
          if (error) throw error
          alert('新增成功！')
        }
        this.closeForm()
        this.fetchCustomers()
      } catch (err) {
        alert('儲存失敗: ' + err.message)
      }
    },
    async deleteCustomer(customer) {
      if (!confirm(`確定要刪除會員 ${customer.name} (${customer.code})？`)) return
      try {
        const { error } = await supabase.from('erp_customers').delete().eq('id', customer.id)
        if (error) throw error
        alert('刪除成功')
        this.fetchCustomers()
      } catch (err) {
        alert('刪除失敗: ' + err.message)
      }
    }
  }
}
</script>
