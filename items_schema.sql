-- 1. erp_items (商品主檔)
CREATE TABLE IF NOT EXISTS public.erp_items (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER REFERENCES public.erp_tenants(id) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    specification TEXT,
    unit VARCHAR(20) DEFAULT '件',
    lifecycle_status VARCHAR(20) DEFAULT 'ACTIVE',
    cost_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    retail_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    color VARCHAR(50),
    size VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. erp_order_items (銷貨單明細)
CREATE TABLE IF NOT EXISTS public.erp_order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES public.erp_orders(id) ON DELETE CASCADE NOT NULL,
    item_id INTEGER REFERENCES public.erp_items(id) NOT NULL,
    item_code VARCHAR(20),
    item_name VARCHAR(255),
    specification VARCHAR(255),
    qty NUMERIC(10, 2) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(12, 2) NOT NULL,
    tax NUMERIC(10, 2) DEFAULT 0.05,
    fifo_lot_id INTEGER
);

-- 插入測試商品資料
INSERT INTO public.erp_items (tenant_id, sku, name, specification, retail_price, cost_price, color, size) VALUES
(1, 'TEST-SKU-001', '特級棉質 T-Shirt', '100%純棉', 590, 200, '白色', 'M'),
(1, 'TEST-SKU-002', '特級棉質 T-Shirt', '100%純棉', 590, 200, '黑色', 'L'),
(1, 'TEST-SKU-003', '防潑水機能外套', 'GORE-TEX', 3500, 1500, '深藍', 'XL'),
(1, 'TEST-SKU-004', '經典直筒牛仔褲', '丹寧布', 1200, 450, '深藍', '32'),
(1, 'TEST-SKU-005', '復古文青粗框眼鏡', '板料材質', 800, 150, '黑框', '均碼')
ON CONFLICT (sku) DO NOTHING;
