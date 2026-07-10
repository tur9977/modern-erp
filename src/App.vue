<template>
  <div>
    <nav style="padding: 1rem; background-color: #f8f9fa; border-bottom: 1px solid #dee2e6; display: flex; gap: 1rem;">
      <router-link to="/orders" style="text-decoration: none; color: #495057; font-weight: bold;">📦 銷貨單系統</router-link>
      <router-link to="/customers" style="text-decoration: none; color: #495057; font-weight: bold;">👥 客戶管理</router-link>
    </nav>
    <main style="padding: 2rem;">
      <router-view></router-view>
    </main>
  </div>
</template>

<script setup>
// Main App Component
</script>

<style>
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  background-color: #f4f6f8;
}
.router-link-active {
  color: #007bff !important;
}
</style>
