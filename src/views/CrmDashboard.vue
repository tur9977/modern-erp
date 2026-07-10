<template>
  <div class="crm-dashboard animate-fade-in">
    <div class="page-header">
      <h1>👥 CRM 客戶關係管理中心</h1>
      <p class="subtitle">客戶資料管理、通路歸屬設定、會員分級與風控</p>
    </div>

    <!-- Mind Map Flow Diagram -->
    <div class="glass-card mindmap-card">
      <h2>📊 CRM 核心業務心智流程圖</h2>
      <p class="mindmap-hint">點擊任一流程節點，進入該系統處理業務</p>

      <div class="tree-container">
        <!-- Root -->
        <div class="tree-level">
          <div class="node root-node" @click="navigateTo('/customers')">
            <div class="icon">👥</div>
            <div class="title">建立/匯入客戶資料</div>
            <div class="subtitle">cr_custreg</div>
          </div>
        </div>

        <div class="vertical-line"></div>
        <div class="node decision-node">
          <div class="title">客戶類型</div>
        </div>
        <div class="vertical-line"></div>

        <div class="horizontal-line-group">
            <div class="horizontal-line"></div>
        </div>

        <!-- Branches Level 1 -->
        <div class="tree-level branches-3">
          <div class="branch">
            <div class="vertical-line-short"></div>
            <div class="edge-label">RETAIL</div>
            <div class="node type-retail" @click="navigateTo('/customers?type=RETAIL')">
              <div class="title">一般會員管理</div>
            </div>
            <div class="vertical-line"></div>
            <div class="node action-node" @click="navigateTo('/member-tiers')">
              <div class="icon">⭐</div>
              <div class="title">會員等級/紅利點數</div>
            </div>
          </div>

          <div class="branch">
            <div class="vertical-line-short"></div>
            <div class="edge-label">AGENT</div>
            <div class="node type-agent" @click="navigateTo('/customers?type=AGENT')">
              <div class="title">代理商管理</div>
            </div>
            <div class="vertical-line"></div>
            <div class="node action-node" @click="navigateTo('/consignments')">
              <div class="icon">🛡️</div>
              <div class="title">應收帳款與授信額度</div>
              <div class="subtitle">Risk Control 庫存風控</div>
            </div>
          </div>

          <div class="branch">
            <div class="vertical-line-short"></div>
            <div class="edge-label">CHANNEL</div>
            <div class="node type-channel" @click="navigateTo('/customers?type=CHANNEL')">
              <div class="title">通路商管理</div>
              <div class="subtitle">cs_cust</div>
            </div>
            <!-- Connects to the same Risk Control conceptually, but we draw a direct line down for simplicity -->
            <div class="vertical-line"></div>
            <div class="node action-node" @click="navigateTo('/consignments')">
              <div class="icon">🛡️</div>
              <div class="title">應收帳款與授信額度</div>
              <div class="subtitle">Risk Control 庫存風控</div>
            </div>
          </div>
        </div>

        <!-- Bottom Merger -->
        <div class="horizontal-line-group-bottom">
            <div class="horizontal-line"></div>
        </div>
        <div class="vertical-line-short"></div>

        <!-- Leaf -->
        <div class="tree-level">
          <div class="node target-node" @click="navigateTo('/customers')">
            <div class="icon">👁️</div>
            <div class="title">360度客戶視圖</div>
            <div class="subtitle">統一客製化歷史價格與消費紀錄</div>
          </div>
        </div>

      </div>
    </div>

    <!-- KPI Cards -->
    <div class="kpi-row">
      <div class="glass-card stat-card">
        <span class="stat-label">總客戶數</span>
        <span class="stat-value">{{ kpi.total }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">一般會員 (B2C)</span>
        <span class="stat-value" style="color: #6366f1;">{{ kpi.retail }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">代理商 (B2B)</span>
        <span class="stat-value" style="color: #f59e0b;">{{ kpi.agent }}</span>
      </div>
      <div class="glass-card stat-card">
        <span class="stat-label">待結帳託售單</span>
        <span class="stat-value" style="color: #ef4444;">{{ kpi.pendingConsignment }}</span>
      </div>
    </div>

  </div>
</template>

<script>
import { supabase } from '../supabase'

export default {
  name: 'CrmDashboard',
  data() {
    return {
      kpi: {
        total: 0,
        retail: 0,
        agent: 0,
        channel: 0,
        pendingConsignment: 0
      }
    }
  },
  mounted() {
    this.fetchKPIs()
  },
  methods: {
    navigateTo(path) {
      this.$router.push(path)
    },
    async fetchKPIs() {
      try {
        const [resCust, resClm] = await Promise.all([
          supabase.from('erp_customers/', { params: { tenant_id: 1 } }),
          supabase.from('erp_consignments/', { params: { tenant_id: 1 } })
        ])
        const customers = resCust.data
        this.kpi.total = customers.length
        this.kpi.retail = customers.filter(c => c.type === 'RETAIL').length
        this.kpi.agent = customers.filter(c => c.type === 'AGENT').length
        this.kpi.channel = customers.filter(c => c.type === 'CHANNEL').length
        this.kpi.pendingConsignment = (resClm.data || []).filter(
          c => c.status === 'SHIPPED' || c.status === 'PARTIAL'
        ).length
      } catch (err) {
        console.error('Failed to load CRM KPIs:', err)
      }
    }
  }
}
</script>

<style scoped>
.crm-dashboard { padding: 2rem; max-width: 1400px; margin: 0 auto; }
.page-header { margin-bottom: 1.5rem; }
.page-header h1 { font-size: 2rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem; }
.subtitle { color: var(--text-secondary); font-size: 0.95rem; }

.kpi-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-top: 1.5rem; }
.stat-card { display: flex; flex-direction: column; gap: 0.3rem; }
.stat-label { font-size: 0.8rem; color: var(--text-muted); }
.stat-value { font-size: 2rem; font-weight: 700; color: var(--text-primary); }

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

.branches-3 {
  display: flex;
  justify-content: space-between;
  width: 80%;
  gap: 2rem;
}

.branch {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
}

.node {
  padding: 1rem 1.5rem;
  border-radius: 8px;
  background: var(--bg-input);
  border: 1px solid var(--border-glass);
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  min-width: 160px;
}
.node:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 15px rgba(0,0,0,0.2);
  border-color: var(--color-primary);
}

.root-node { background: rgba(99,102,241,0.1); border-color: #6366f1; }
.decision-node { background: rgba(255,255,255,0.05); transform: rotate(45deg); padding: 1.5rem; margin: 1rem 0; cursor: default; }
.decision-node:hover { transform: rotate(45deg); border-color: inherit; box-shadow: none; }
.decision-node .title { transform: rotate(-45deg); font-weight: bold; }

.type-retail { border-color: #6366f1; border-top-width: 4px; }
.type-agent { border-color: #f59e0b; border-top-width: 4px; }
.type-channel { border-color: #10b981; border-top-width: 4px; }

.action-node { background: rgba(255,255,255,0.02); border-radius: 20px; }
.target-node { background: rgba(236,72,153,0.1); border-color: #ec4899; }

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

.horizontal-line-group-bottom {
  width: 80%;
  display: flex;
  justify-content: center;
}
.horizontal-line-group-bottom .horizontal-line {
  width: calc(100% - 33.33%);
  height: 2px;
  background-color: var(--border-glass);
  margin-top: 40px;
}
</style>