<template>
  <div class="inventory-items">
    <div class="header-actions">
      <h2>商品主檔 (Inventory Items)</h2>
      <button class="btn btn-primary" @click="openModal()">+ 新增商品</button>
    </div>

    <div class="table-container glass-card">
      <table v-if="items.length > 0">
        <thead>
          <tr>
            <th>代號 (SKU)</th>
            <th>商品名稱</th>
            <th>啟用批號管控</th>
            <th>啟用效期管控</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in items" :key="item.id">
            <td style="font-weight: 600; color: var(--color-primary);">{{ item.sku }}</td>
            <td>{{ item.name }}</td>
            <td>
              <span :class="['badge', item.has_batches ? 'badge-success' : 'badge-secondary']">
                {{ item.has_batches ? '是' : '否' }}
              </span>
            </td>
            <td>
              <span :class="['badge', item.has_expiry ? 'badge-warning' : 'badge-secondary']">
                {{ item.has_expiry ? '是' : '否' }}
              </span>
            </td>
            <td>
              <button class="btn btn-sm btn-secondary" @click="openModal(item)">編輯</button>
              <button class="btn btn-sm btn-danger" @click="deleteItem(item.id)">刪除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">目前沒有商品，請新增。</div>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="modal-backdrop" @click.self="closeModal">
      <div class="modal-card glass-card">
        <h3>{{ editingItem ? '編輯商品' : '新增商品' }}</h3>
        <form @submit.prevent="saveItem" class="form-group">
          <label>代號 (SKU) *</label>
          <input type="text" v-model="form.sku" required placeholder="例: T0041003" />

          <label>商品名稱 *</label>
          <input type="text" v-model="form.name" required placeholder="例: 特級棉質 T-Shirt" />

          <div class="checkbox-group">
            <label class="checkbox-label">
              <input type="checkbox" v-model="form.has_batches" />
              啟用批號管控 (Batch Tracking)
            </label>
            <label class="checkbox-label">
              <input type="checkbox" v-model="form.has_expiry" />
              啟用效期管控 (Expiry Tracking)
            </label>
          </div>

          <div class="modal-actions">
            <button type="button" class="btn btn-secondary" @click="closeModal">取消</button>
            <button type="submit" class="btn btn-primary">儲存</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'InventoryItems',
  data() {
    return {
      items: [],
      showModal: false,
      editingItem: null,
      form: {
        tenant_id: 1,
        sku: '',
        name: '',
        has_batches: false,
        has_expiry: false
      }
    }
  },
  mounted() {
    this.fetchItems()
  },
  methods: {
    async fetchItems() {
      try {
        const { data, error } = await supabase.from('erp_items').select('*').order('created_at', { ascending: false })
        if (error) throw error
        this.items = data || []
      } catch (err) {
        console.error(err)
      }
    },
    openModal(item = null) {
      this.editingItem = item
      if (item) {
        this.form = { ...item }
      } else {
        this.form = { tenant_id: 1, sku: '', name: '', has_batches: false, has_expiry: false }
      }
      this.showModal = true
    },
    closeModal() {
      this.showModal = false
      this.editingItem = null
    },
    async saveItem() {
      try {
        if (this.editingItem) {
          const { error } = await supabase.from('erp_items').update({
            sku: this.form.sku,
            name: this.form.name,
            has_batches: this.form.has_batches,
            has_expiry: this.form.has_expiry
          }).eq('id', this.editingItem.id)
          if (error) throw error
        } else {
          const { error } = await supabase.from('erp_items').insert([this.form])
          if (error) throw error
        }
        this.fetchItems()
        this.closeModal()
      } catch (err) {
        alert('儲存失敗: ' + err.message)
      }
    },
    async deleteItem(id) {
      if (!confirm('確定刪除此商品？')) return
      try {
        const { error } = await supabase.from('erp_items').delete().eq('id', id)
        if (error) throw error
        this.fetchItems()
      } catch (err) {
        alert('刪除失敗: ' + err.message)
      }
    }
  }
}
</script>

<style scoped>
.inventory-items { padding: 2rem; }
.header-actions { display: flex; justify-content: space-between; margin-bottom: 1.5rem; }
table { width: 100%; border-collapse: collapse; color: var(--text-primary); }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.1); }
th { color: var(--text-muted); font-weight: 500; }
.badge { padding: 4px 8px; border-radius: 4px; font-size: 0.8rem; }
.badge-success { background: rgba(16, 185, 129, 0.2); color: #34d399; }
.badge-warning { background: rgba(245, 158, 11, 0.2); color: #fbbf24; }
.badge-secondary { background: rgba(156, 163, 175, 0.2); color: #9ca3af; }
.btn-sm { padding: 4px 8px; font-size: 0.85rem; margin-right: 5px; }
.btn-danger { background: rgba(239, 68, 68, 0.2); color: #ef4444; border: none; }

/* Modal Styles */
.modal-backdrop { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); display: flex; justify-content: center; align-items: center; z-index: 1000; backdrop-filter: blur(4px); }
.modal-card { width: 450px; padding: 2rem; border-radius: 12px; }
.form-group label { display: block; margin-bottom: 5px; color: var(--text-muted); }
.form-group input[type="text"] { width: 100%; padding: 8px; margin-bottom: 15px; border-radius: 4px; border: 1px solid var(--border-glass); background: var(--bg-input); color: white; }
.checkbox-group { display: flex; flex-direction: column; gap: 10px; margin-bottom: 20px; }
.checkbox-label { display: flex; align-items: center; gap: 8px; color: var(--text-primary); cursor: pointer; }
.modal-actions { display: flex; justify-content: flex-end; gap: 10px; border-top: 1px solid var(--border-glass); padding-top: 1rem; margin-top: 1rem; }
</style>
