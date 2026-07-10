-- Supabase Serverless ERP Schema

-- 1. tenants (租戶)
CREATE TABLE IF NOT EXISTS public.tenants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. channels (銷售通路)
CREATE TABLE IF NOT EXISTS public.channels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) DEFAULT 'ONLINE',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. payment_methods (付款方式)
CREATE TABLE IF NOT EXISTS public.payment_methods (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) DEFAULT 'CREDIT_CARD',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. collection_targets (請款對象)
CREATE TABLE IF NOT EXISTS public.collection_targets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    tax_id VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. customers (客戶)
CREATE TABLE IF NOT EXISTS public.customers (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER REFERENCES public.tenants(id) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) DEFAULT 'B2C',
    mobile VARCHAR(20),
    email VARCHAR(100),
    invoice_address TEXT,
    delivery_address TEXT,
    tier_id INTEGER,
    sales_emp_id INTEGER,
    payment_method VARCHAR(50) DEFAULT '信用卡',
    billing_target VARCHAR(100),
    note TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. orders (銷貨單)
CREATE TABLE IF NOT EXISTS public.orders (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER REFERENCES public.tenants(id) NOT NULL,
    order_no VARCHAR(50) NOT NULL UNIQUE,
    type VARCHAR(20) DEFAULT 'DIRECT_SALE',
    order_date DATE NOT NULL,
    accounting_date DATE,
    employee_id VARCHAR(50),
    department_id VARCHAR(50),
    project_id VARCHAR(50),
    remarks TEXT,
    channel_id INTEGER REFERENCES public.channels(id) NOT NULL,
    collection_target_id INTEGER REFERENCES public.collection_targets(id) NOT NULL,
    payment_method_id INTEGER REFERENCES public.payment_methods(id) NOT NULL,
    customer_id INTEGER REFERENCES public.customers(id),
    customer_name VARCHAR(100),
    customer_phone VARCHAR(20),
    customer_address VARCHAR(500),
    subtotal NUMERIC(12, 2) DEFAULT 0,
    tax NUMERIC(12, 2) DEFAULT 0,
    total NUMERIC(12, 2) DEFAULT 0,
    status VARCHAR(30) DEFAULT 'DRAFT',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Initial Data
INSERT INTO public.tenants (name) VALUES ('Double ERP 預設租戶') ON CONFLICT DO NOTHING;
INSERT INTO public.channels (name, type) VALUES ('自營官網', 'ONLINE'), ('實體門市', 'RETAIL'), ('蝦皮商城', 'ONLINE') ON CONFLICT DO NOTHING;
INSERT INTO public.payment_methods (name, type) VALUES ('信用卡', 'CREDIT_CARD'), ('銀行轉帳', 'BANK_TRANSFER'), ('貨到付款', 'COD') ON CONFLICT DO NOTHING;
INSERT INTO public.collection_targets (name) VALUES ('綠界科技'), ('藍新金流'), ('蝦皮購物') ON CONFLICT DO NOTHING;
