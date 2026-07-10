<template>
  <div class="inventory-dashboard animate-fade-in">
    <div class="page-header">
      <h1>📦 採購與庫存系統中心</h1>
      <p class="subtitle">採購下單、進貨驗收、批號效期追蹤與庫存盤點 (FIFO)</p>
    </div>

    <!-- Mind Map Flow Diagram -->
    <div class="glass-card mindmap-card">
      <h2>📊 採購與庫存核心業務流程圖</h2>
      <p class="mindmap-hint">點擊任一流程節點，進入該系統處理業務</p>

      <div class="tree-container">
        <!-- Level 1: 採購下單 -->
        <div class="tree-level">
          <div class="node root-node" @click="navigateTo('/purchase-orders')">
            <div class="icon">📝</div>
            <div class="title">請購與採購下單</div>
            <div class="subtitle">Purchase Orders (PO)</div>
          </div>
        </div>

        <div class="vertical-line"></div>

        <!-- Level 2: 進貨驗收 -->
        <div class="tree-level">
          <div class="node target-node" @click="navigateTo('/purchase-orders')">
            <div class="icon">📥</div>
            <div class="title">進貨驗收 (Goods Receipt)</div>
            <div class="subtitle">強制輸入批號與有效期限</div>
          </div>
        </div>

        <div class="vertical-line"></div>

        <div class="horizontal-line-group">
            <div class="horizontal-line"></div>
        </div>

        <!-- Level 3: 庫存管理分支 -->
        <div class="tree-level branches-2">
          <div class="branch">
            <div class="vertical-line-short"></div>
            <div class="edge-label">商品主檔</div>
            <div class="node type-retail" @click="navigateTo('/inventory/items')">
              <div class="title">商品設定</div>
              <div class="subtitle">批號/效期管控開關</div>
            </div>
          </div>

          <div class="branch">
            <div class="vertical-line-short"></div>
            <div class="edge-label">批號追蹤</div>
            <div class="node type-agent" @click="navigateTo('/inventory/lots')">
              <div class="title">FIFO 庫存批次</div>
              <div class="subtitle">Lot Tracking / 快過期警示</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'InventoryDashboard',
  methods: {
    navigateTo(path) {
      this.$router.push(path)
    }
  }
}
</script>

<style scoped>
.inventory-dashboard { padding: 2rem; max-width: 1400px; margin: 0 auto; }
.page-header { margin-bottom: 1.5rem; }
.page-header h1 { font-size: 2rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem; }
.subtitle { color: var(--text-secondary); font-size: 0.95rem; }

.mindmap-card { 
  margin-bottom: 1.5rem; 
  padding: 2rem;
  background: var(--bg-card);
  overflow-x: auto;
}
.mindmap-card h2 { margin-bottom: 0.5rem; text-align: center; }
.mindmap-hint { color: var(--text-muted); font-size: 0.85rem; margin-bottom: 2rem; text-align: center; }

/* Tree Flowchart CSS */
.tree-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  min-width: 800px;
}

.tree-level {
  display: flex;
  justify-content: center;
  width: 100%;
}

.branches-2 {
  display: flex;
  justify-content: space-around;
  width: 60%;
  gap: 2rem;
}

.branch {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
}

.node {
  padding: 1.2rem 1.5rem;
  border-radius: 8px;
  background: var(--bg-input);
  border: 1px solid var(--border-glass);
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  min-width: 180px;
}
.node:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 15px rgba(0,0,0,0.2);
  border-color: var(--color-primary);
}

.root-node { background: rgba(99,102,241,0.1); border-color: #6366f1; }
.target-node { background: rgba(236,72,153,0.1); border-color: #ec4899; }

.type-retail { border-color: #6366f1; border-top-width: 4px; }
.type-agent { border-color: #f59e0b; border-top-width: 4px; }
.type-channel { border-color: #10b981; border-top-width: 4px; }

.icon { font-size: 1.5rem; margin-bottom: 0.3rem; }
.title { font-weight: 600; font-size: 0.95rem; color: var(--text-primary); }
.subtitle { font-size: 0.75rem; color: var(--text-muted); margin-top: 0.2rem; }

.edge-label {
  background: var(--bg-card);
  padding: 0.2rem 0.5rem;
  font-size: 0.75rem;
  color: var(--color-primary);
  border: 1px solid var(--border-glass);
  border-radius: 12px;
  margin-bottom: 0.5rem;
  z-index: 2;
}

/* Connecting Lines */
.vertical-line {
  width: 2px;
  height: 40px;
  background-color: var(--border-glass);
}
.vertical-line-short {
  width: 2px;
  height: 20px;
  background-color: var(--border-glass);
}

.horizontal-line-group {
  width: 80%;
  display: flex;
  justify-content: center;
}
.horizontal-line-group .horizontal-line {
  width: calc(100% - 33.33%);
  height: 2px;
  background-color: var(--border-glass);
}
</style>
