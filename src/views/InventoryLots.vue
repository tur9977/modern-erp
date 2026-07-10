<template>
  <div class="inventory-lots">
    <div class="header-actions">
      <h2>FIFO 庫存批次 (Lot Tracking)</h2>
      <div class="legend">
        <span class="legend-item danger">已過期</span>
        <span class="legend-item warning">30天內到期</span>
        <span class="legend-item normal">安全</span>
      </div>
    </div>

    <div class="table-container glass-panel">
      <table v-if="lots.length > 0">
        <thead>
          <tr>
            <th>商品</th>
            <th>批號</th>
            <th>目前數量</th>
            <th>入庫日期</th>
            <th>有效期限</th>
            <th>狀態</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="lot in lots" :key="lot.id" :class="getRowClass(lot)">
            <td>{{ lot.item?.name || lot.item_id }}</td>
            <td>{{ lot.lot_number || '無' }}</td>
            <td class="qty">{{ lot.qty }}</td>
            <td>{{ formatDate(lot.received_date) }}</td>
            <td>{{ formatDate(lot.expiration_date) || '無限期' }}</td>
            <td>
              <span :class="['status-badge', getRowClass(lot)]">
                {{ getStatusText(lot) }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-else class="empty-state">目前庫存中沒有任何批次資料。</div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'InventoryLots',
  data() {
    return {
      lots: []
    }
  },
  mounted() {
    this.fetchLots()
  },
  methods: {
    async fetchLots() {
      try {
        const res = await supabase.from('erp_inventory-lots/')
        // Sort by expiration_date asc
        this.lots = res.data.sort((a, b) => {
          if (!a.expiration_date) return 1;
          if (!b.expiration_date) return -1;
          return new Date(a.expiration_date) - new Date(b.expiration_date);
        })
      } catch (err) {
        console.error(err)
      }
    },
    formatDate(dateStr) {
      if (!dateStr) return '';
      return dateStr.split('T')[0];
    },
    getDaysUntilExpiry(lot) {
      if (!lot.expiration_date) return 9999;
      const exp = new Date(lot.expiration_date);
      const today = new Date();
      const diffTime = exp - today;
      return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    },
    getRowClass(lot) {
      if (!lot.expiration_date || lot.qty <= 0) return 'row-normal';
      const days = this.getDaysUntilExpiry(lot);
      if (days < 0) return 'row-danger';
      if (days <= 30) return 'row-warning';
      return 'row-normal';
    },
    getStatusText(lot) {
      if (lot.qty <= 0) return '已耗盡';
      if (!lot.expiration_date) return '安全';
      const days = this.getDaysUntilExpiry(lot);
      if (days < 0) return `過期 ${Math.abs(days)} 天`;
      if (days <= 30) return `剩餘 ${days} 天`;
      return '安全';
    }
  }
}
</script>

<style scoped>
.inventory-lots { padding: 2rem; }
.header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
.legend { display: flex; gap: 15px; }
.legend-item { display: flex; align-items: center; font-size: 0.85rem; color: var(--text-muted); }
.legend-item::before { content: ''; display: inline-block; width: 12px; height: 12px; border-radius: 50%; margin-right: 6px; }
.legend-item.danger::before { background: rgba(239, 68, 68, 0.8); }
.legend-item.warning::before { background: rgba(245, 158, 11, 0.8); }
.legend-item.normal::before { background: rgba(16, 185, 129, 0.8); }

.glass-panel { background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 12px; overflow-x: auto; }
table { width: 100%; border-collapse: collapse; color: var(--text-primary); }
th, td { padding: 12px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.05); }
th { color: var(--text-muted); font-weight: 500; }
.qty { font-family: monospace; font-size: 1.1rem; }

/* Status Styles */
tr.row-danger { background: rgba(239, 68, 68, 0.1); }
tr.row-danger td { color: #fca5a5; }
tr.row-warning { background: rgba(245, 158, 11, 0.1); }
tr.row-warning td { color: #fcd34d; }

.status-badge { padding: 4px 8px; border-radius: 4px; font-size: 0.8rem; font-weight: bold; }
.status-badge.row-danger { background: rgba(239, 68, 68, 0.2); color: #ef4444; }
.status-badge.row-warning { background: rgba(245, 158, 11, 0.2); color: #fbbf24; }
.status-badge.row-normal { background: rgba(16, 185, 129, 0.2); color: #34d399; }
</style>
