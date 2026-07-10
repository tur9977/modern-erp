import { createRouter, createWebHistory } from 'vue-router'
import Orders from '../views/Orders.vue'
import Customers from '../views/Customers.vue'

const routes = [
  {
    path: '/',
    redirect: '/orders'
  },
  {
    path: '/orders',
    name: 'Orders',
    component: Orders
  },
  {
    path: '/customers',
    name: 'Customers',
    component: Customers
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
