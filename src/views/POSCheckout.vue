<template>
  <div class="animate-fade-in">
    <h1>POS 收銀台</h1>
    <p class="subtitle">DOUBLE ERP 銷售交易結帳介面</p>

    <!-- Error/Success Messages -->
    <div v-if="errorMessage" class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
      {{ errorMessage }}
    </div>
    <div v-if="successMessage" class="alert alert-success">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
      {{ successMessage }}
    </div>

    <div class="grid-cols-2" style="gap: 2rem;">
      <!-- Left: Cart Items -->
      <div class="glass-card">
        <h2 style="display: flex; align-items: center; gap: 0.5rem;">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
          購物車
          <span class="badge">{{ cartItems.length }} 項</span>
        </h2>

        <!-- Product Search -->
        <div class="form-group" style="margin: 1rem 0;">
          <label>新增商品</label>
          <div style="display: flex; gap: 0.5rem;">
            <input v-model="productSearch" type="text" placeholder="輸入 SKU 或商品名稱搜尋..." @input="searchProducts" />
            <button class="btn btn-secondary" @click="searchProducts" :disabled="!productSearch">搜尋</button>
          </div>
          <!-- Search Results Dropdown -->
          <div v-if="searchResults.length > 0" class="search-dropdown">
            <div v-for="product in searchResults" :key="product.sku" class="search-item" @click="addToCart(product)">
              <span class="sku">{{ product.sku }}</span>
              <span class="name">{{ product.name }}</span>
              <span class="price">${{ product.price }}</span>
            </div>
          </div>
        </div>

        <!-- Cart Table -->
        <table v-if="cartItems.length > 0">
          <thead>
            <tr>
              <th>商品名稱</th>
              <th>單價</th>
              <th>數量</th>
              <th>小計</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in cartItems" :key="item.sku">
              <td>{{ item.name }} <span class="sku-tag">{{ item.sku }}</span></td>
              <td>${{ item.price }}</td>
              <td>
                <div class="qty-control">
                  <button @click="decreaseQty(index)" :disabled="item.quantity <= 1">-</button>
                  <input type="number" v-model.number="item.quantity" min="1" @change="updateQty(index, $event)" />
                  <button @click="increaseQty(index)">+</button>
                </div>
              </td>
              <td class="subtotal">${{ (item.price * item.quantity).toLocaleString() }}</td>
              <td><button class="btn-icon btn-danger" @click="removeItem(index)">×</button></td>
            </tr>
          </tbody>
        </table>
        <div v-else class="empty-state">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
          <p>購物車是空的，請新增商品</p>
        </div>

        <!-- Cart Summary -->
        <div v-if="cartItems.length > 0" class="cart-summary">
          <div class="summary-row">
            <span>商品小計</span>
            <span>${{ subtotal.toLocaleString() }}</span>
          </div>
          <div class="summary-row">
            <span>稅金 (5%)</span>
            <span>${{ tax.toLocaleString() }}</span>
          </div>
          <div class="summary-row total">
            <span>合計</span>
            <span>${{ total.toLocaleString() }}</span>
          </div>
        </div>
      </div>

      <!-- Right: Payment -->
      <div class="glass-card">
        <h2 style="display: flex; align-items: center; gap: 0.5rem;">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
          付款資訊
        </h2>

        <!-- Customer Selection -->
        <div class="form-group">
          <label>客戶</label>
          <select v-model="selectedCustomerId">
            <option :value="null">一般客戶（無會員）</option>
            <option v-for="customer in customers" :key="customer.id" :value="customer.id">
              {{ customer.name }} ({{ customer.phone }})
            </option>
          </select>
        </div>

        <!-- Payment Method -->
        <div class="form-group">
          <label>付款方式</label>
          <div class="payment-methods">
            <label class="payment-option" :class="{ active: paymentMethod === 'cash' }">
              <input type="radio" v-model="paymentMethod" value="cash" />
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
              現金
            </label>
            <label class="payment-option" :class="{ active: paymentMethod === 'credit' }">
              <input type="radio" v-model="paymentMethod" value="credit" />
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
              信用卡
            </label>
            <label class="payment-option" :class="{ active: paymentMethod === 'linepay' }">
              <input type="radio" v-model="paymentMethod" value="linepay" />
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4"/><circle cx="12" cy="12" r="10"/></svg>
              LINE Pay
            </label>
          </div>
        </div>

        <!-- Cash Payment Details -->
        <div v-if="paymentMethod === 'cash'" class="form-group">
          <label>收到金額</label>
          <input type="number" v-model.number="cashReceived" placeholder="輸入收到金額" min="0" />
          <div class="quick-cash-buttons">
            <button v-for="amt in quickAmounts" :key="amt" class="btn btn-outline" @click="cashReceived = amt">
              ${{ amt.toLocaleString() }}
            </button>
          </div>
        </div>

        <!-- Change Calculation -->
        <div v-if="paymentMethod === 'cash' && cashReceived > 0" class="change-display" :class="{ 'enough': change >= 0, 'not-enough': change < 0 }">
          <div class="change-row">
            <span>應收金額</span>
            <span>${{ total.toLocaleString() }}</span>
          </div>
          <div class="change-row">
            <span>收到金額</span>
            <span>${{ cashReceived.toLocaleString() }}</span>
          </div>
          <div class="change-row highlight">
            <span>找零</span>
            <span>${{ Math.max(0, change).toLocaleString() }}</span>
          </div>
          <div v-if="change < 0" class="warning-text">
            金額不足！尚欠 ${{ Math.abs(change).toLocaleString() }}
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="action-buttons" style="margin-top: 2rem;">
          <button class="btn btn-secondary" @click="clearCart" :disabled="cartItems.length === 0 || submitting">
            清空購物車
          </button>
          <button class="btn btn-primary btn-large" @click="processPayment" :disabled="cartItems.length === 0 || submitting || (paymentMethod === 'cash' && change < 0)">
            <span v-if="submitting">
              <svg class="spinner" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
              處理中...
            </span>
            <span v-else>完成交易</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Recent Transactions -->
    <div class="glass-card" style="margin-top: 2rem;">
      <h2>最近交易</h2>
      <table>
        <thead>
          <tr>
            <th>交易編號</th>
            <th>時間</th>
            <th>客戶</th>
            <th>金額</th>
            <th>付款方式</th>
            <th>狀態</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="txn in recentTransactions" :key="txn.id">
            <td><span class="sku-tag">{{ txn.id }}</span></td>
            <td>{{ formatDateTime(txn.created_at) }}</td>
            <td>{{ txn.customer_name || '一般客戶' }}</td>
            <td>${{ txn.total.toLocaleString() }}</td>
            <td>{{ paymentMethodLabel(txn.payment_method) }}</td>
            <td><span :class="'badge badge-' + (txn.status === 'completed' ? 'success' : 'warning')">{{ txn.status }}</span></td>
          </tr>
          <tr v-if="recentTransactions.length === 0">
            <td colspan="6" class="text-center text-muted">尚無交易記錄</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

// Cart state
const cartItems = ref([]);
const productSearch = ref('');
const searchResults = ref([]);
const searchTimeout = ref(null);

// Payment state
const paymentMethod = ref('cash');
const cashReceived = ref(0);
const quickAmounts = [1000, 2000, 5000, 10000];

// Customer state
const customers = ref([]);
const selectedCustomerId = ref(null);

// UI state
const errorMessage = ref('');
const successMessage = ref('');
const submitting = ref(false);

// Recent transactions
const recentTransactions = ref([]);

// Computed
const subtotal = computed(() => {
  return cartItems.value.reduce((sum, item) => sum + item.price * item.quantity, 0);
});

const tax = computed(() => {
  return Math.round(subtotal.value * 0.05);
});

const total = computed(() => {
  return subtotal.value + tax.value;
});

const change = computed(() => {
  return cashReceived.value - total.value;
});

// Methods
function searchProducts() {
  if (searchTimeout.value) clearTimeout(searchTimeout.value);
  if (!productSearch.value.trim()) {
    searchResults.value = [];
    return;
  }
  searchTimeout.value = setTimeout(async () => {
    try {
      const res = await apiClient.get(`/products?search=${encodeURIComponent(productSearch.value)}`);
      searchResults.value = res.data.products || res.data || [];
    } catch (err) {
      console.error('搜尋錯誤:', err);
      searchResults.value = [];
    }
  }, 300);
}

function addToCart(product) {
  const existing = cartItems.value.find(item => item.sku === product.sku);
  if (existing) {
    existing.quantity++;
  } else {
    cartItems.value.push({
      sku: product.sku,
      name: product.name,
      price: product.price,
      quantity: 1
    });
  }
  productSearch.value = '';
  searchResults.value = [];
}

function increaseQty(index) {
  cartItems.value[index].quantity++;
}

function decreaseQty(index) {
  if (cartItems.value[index].quantity > 1) {
    cartItems.value[index].quantity--;
  }
}

function updateQty(index, event) {
  const val = parseInt(event.target.value);
  if (val < 1) cartItems.value[index].quantity = 1;
  else cartItems.value[index].quantity = val;
}

function removeItem(index) {
  cartItems.value.splice(index, 1);
}

function clearCart() {
  cartItems.value = [];
  cashReceived.value = 0;
  selectedCustomerId.value = null;
  errorMessage.value = '';
  successMessage.value = '';
}

async function processPayment() {
  if (cartItems.value.length === 0) return;
  if (paymentMethod.value === 'cash' && change.value < 0) return;

  errorMessage.value = '';
  successMessage.value = '';
  submitting.value = true;

  try {
    const payload = {
      customer_id: selectedCustomerId.value,
      items: cartItems.value.map(item => ({
        sku: item.sku,
        quantity: item.quantity,
        unit_price: item.price
      })),
      subtotal: subtotal.value,
      tax: tax.value,
      total: total.value,
      payment_method: paymentMethod.value,
      cash_received: paymentMethod.value === 'cash' ? cashReceived.value : total.value,
      change: paymentMethod.value === 'cash' ? Math.max(0, change.value) : 0
    };

    const res = await apiClient.post('/pos/transactions', payload);

    const result = res.data;
    successMessage.value = `交易完成！交易編號：${result.transaction_id || result.id}`;
    await loadRecentTransactions();
    clearCart();

    setTimeout(() => { successMessage.value = ''; }, 5000);
  } catch (err) {
    errorMessage.value = err.message;
    setTimeout(() => { errorMessage.value = ''; }, 5000);
  } finally {
    submitting.value = false;
  }
}

async function loadCustomers() {
  try {
    const res = await apiClient.get('/customers');
    customers.value = res.data.customers || res.data || [];
  } catch (err) {
    console.error('載入客戶失敗:', err);
  }
}

async function loadRecentTransactions() {
  try {
    const res = await apiClient.get('/pos/transactions?limit=10');
    recentTransactions.value = res.data.transactions || res.data || [];
  } catch (err) {
    console.error('載入交易記錄失敗:', err);
  }
}

function formatDateTime(dt) {
  if (!dt) return '-';
  const d = new Date(dt);
  return d.toLocaleString('zh-TW');
}

function paymentMethodLabel(method) {
  const labels = { cash: '現金', credit: '信用卡', linepay: 'LINE Pay' };
  return labels[method] || method;
}

// Lifecycle
onMounted(() => {
  loadCustomers();
  loadRecentTransactions();
});
</script>

<style scoped>
.qty-control {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}
.qty-control button {
  width: 28px;
  height: 28px;
  border: 1px solid var(--border-color);
  background: var(--bg-secondary);
  color: var(--text);
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}
.qty-control button:hover:not(:disabled) {
  background: var(--bg-hover);
}
.qty-control button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.qty-control input {
  width: 50px;
  text-align: center;
  padding: 0.25rem;
  border: 1px solid var(--border-color);
  background: var(--bg-secondary);
  color: var(--text);
  border-radius: 4px;
}
.search-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  margin-top: 0.25rem;
  max-height: 240px;
  overflow-y: auto;
  z-index: 100;
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
}
.search-item {
  display: flex;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  cursor: pointer;
  border-bottom: 1px solid var(--border-color);
}
.search-item:last-child { border-bottom: none; }
.search-item:hover { background: var(--bg-hover); }
.search-item .sku { color: var(--text-muted); font-family: monospace; }
.search-item .name { flex: 1; margin: 0 1rem; }
.search-item .price { color: var(--color-primary); font-weight: 600; }
.payment-methods {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}
.payment-option {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}
.payment-option:hover { border-color: var(--color-primary); }
.payment-option.active { border-color: var(--color-primary); background: rgba(99, 102, 241, 0.1); }
.payment-option input { display: none; }
.quick-cash-buttons {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.5rem;
  flex-wrap: wrap;
}
.change-display {
  margin-top: 1.5rem;
  padding: 1rem;
  background: var(--bg-secondary);
  border-radius: 8px;
  border: 2px solid var(--border-color);
}
.change-display.enough { border-color: #10b981; }
.change-display.not-enough { border-color: #ef4444; }
.change-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--border-color);
}
.change-row:last-child { border-bottom: none; }
.change-row.highlight { font-size: 1.25rem; font-weight: 700; color: #10b981; }
.warning-text { color: #ef4444; font-weight: 600; margin-top: 0.5rem; text-align: center; }
.btn-large { padding: 1rem 2rem; font-size: 1.1rem; }
.empty-state {
  text-align: center;
  padding: 3rem;
  color: var(--text-muted);
}
.empty-state svg { opacity: 0.3; margin-bottom: 1rem; }
.cart-summary {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 2px solid var(--border-color);
}
.summary-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
}
.summary-row.total {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-primary);
  margin-top: 0.5rem;
  padding-top: 0.75rem;
  border-top: 2px solid var(--border-color);
}
.sku-tag {
  font-family: monospace;
  font-size: 0.8rem;
  padding: 0.15rem 0.4rem;
  background: var(--bg-secondary);
  border-radius: 4px;
  color: var(--text-muted);
}
.spinner {
  animation: spin 1s linear infinite;
}
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
.form-group { position: relative; }
.alert {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1rem;
}
.alert-error { background: rgba(239, 68, 68, 0.15); border: 1px solid #ef4444; color: #ef4444; }
.alert-success { background: rgba(16, 185, 129, 0.15); border: 1px solid #10b981; color: #10b981; }
.text-center { text-align: center; }
</style>
