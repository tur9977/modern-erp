CREATE TABLE tenants (
	id SERIAL NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	UNIQUE (code)
);

CREATE INDEX ix_tenants_id ON tenants (id);

CREATE TABLE warehouses (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	type VARCHAR(20) NOT NULL, 
	is_active BOOLEAN, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);

CREATE INDEX ix_warehouses_id ON warehouses (id);

CREATE TABLE channels (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	type VARCHAR(20) NOT NULL, 
	enabled BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code)
);

CREATE INDEX ix_channels_id ON channels (id);

CREATE TABLE collection_targets (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	bank_info TEXT, 
	contact_person VARCHAR(100), 
	contact_phone VARCHAR(20), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code)
);

CREATE INDEX ix_collection_targets_id ON collection_targets (id);

CREATE TABLE payment_methods (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	type VARCHAR(20) NOT NULL, 
	fee_rate NUMERIC(5, 4), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code)
);

CREATE INDEX ix_payment_methods_id ON payment_methods (id);

CREATE TABLE items (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	sku VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	specification TEXT, 
	unit VARCHAR(20), 
	lifecycle_status VARCHAR(20), 
	cost_price NUMERIC(12, 2) NOT NULL, 
	retail_price NUMERIC(12, 2) NOT NULL, 
	color VARCHAR(50), 
	size VARCHAR(50), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (sku)
);

CREATE INDEX ix_items_id ON items (id);

CREATE TABLE member_tiers (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	name VARCHAR(50) NOT NULL, 
	code VARCHAR(20) NOT NULL, 
	discount_rate NUMERIC(5, 4) NOT NULL, 
	description VARCHAR(200), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code)
);

CREATE INDEX ix_member_tiers_id ON member_tiers (id);

CREATE TABLE general_ledger (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	gl_no VARCHAR(20) NOT NULL, 
	transaction_date DATE NOT NULL, 
	journal_type VARCHAR(20) NOT NULL, 
	reference_no VARCHAR(50), 
	source_type VARCHAR(20), 
	source_id INTEGER, 
	debit_account VARCHAR(50), 
	credit_account VARCHAR(50), 
	amount NUMERIC(12, 2) NOT NULL, 
	description TEXT, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (gl_no)
);

CREATE INDEX ix_general_ledger_id ON general_ledger (id);

COMMENT ON COLUMN general_ledger.source_type IS 'ORDER / SETTLEMENT / PO / WO / POS / RETURN（SSOT §5.7）';

COMMENT ON COLUMN general_ledger.source_id IS '對應來源單據 ID';

CREATE TABLE departments (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	parent_id INTEGER, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(parent_id) REFERENCES departments (id)
);

CREATE INDEX ix_departments_id ON departments (id);

CREATE TABLE vendors (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(200) NOT NULL, 
	contact_person VARCHAR(100), 
	phone VARCHAR(20), 
	mobile VARCHAR(20), 
	email VARCHAR(100), 
	address TEXT, 
	tax_id VARCHAR(20), 
	payment_terms INTEGER, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code)
);

CREATE INDEX ix_vendors_id ON vendors (id);

CREATE TABLE boms (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(200) NOT NULL, 
	version VARCHAR(20), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);

CREATE INDEX ix_boms_id ON boms (id);

CREATE TABLE promotions (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(200) NOT NULL, 
	type VARCHAR(20) NOT NULL, 
	discount_type VARCHAR(20), 
	discount_value NUMERIC(12, 2), 
	start_date DATE NOT NULL, 
	end_date DATE NOT NULL, 
	min_purchase_qty INTEGER, 
	min_purchase_amount NUMERIC(12, 2), 
	max_discount_amount NUMERIC(12, 2), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);

CREATE INDEX ix_promotions_id ON promotions (id);

CREATE TABLE settlements (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	settlement_no VARCHAR(20) NOT NULL, 
	channel_id INTEGER NOT NULL, 
	collection_target_id INTEGER NOT NULL, 
	payment_method_id INTEGER NOT NULL, 
	consignment_ids JSON, 
	settle_month VARCHAR(7) NOT NULL, 
	total_amount NUMERIC(12, 2), 
	status VARCHAR(20), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (settlement_no), 
	FOREIGN KEY(channel_id) REFERENCES channels (id), 
	FOREIGN KEY(collection_target_id) REFERENCES collection_targets (id), 
	FOREIGN KEY(payment_method_id) REFERENCES payment_methods (id)
);

CREATE INDEX ix_settlements_id ON settlements (id);

CREATE TABLE inventory_transactions (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	warehouse_id INTEGER, 
	customer_id INTEGER, 
	transaction_type VARCHAR(20) NOT NULL, 
	reference_no VARCHAR(50), 
	qty_change NUMERIC(10, 2) NOT NULL, 
	balance_after NUMERIC(10, 2) NOT NULL, 
	fifo_lot_id INTEGER, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(item_id) REFERENCES items (id), 
	FOREIGN KEY(warehouse_id) REFERENCES warehouses (id)
);

CREATE INDEX ix_inventory_transactions_id ON inventory_transactions (id);

CREATE TABLE inventory_lots (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	warehouse_id INTEGER NOT NULL, 
	lot_no VARCHAR(50) NOT NULL, 
	qty_received NUMERIC(10, 2) NOT NULL, 
	qty_remaining NUMERIC(10, 2) NOT NULL, 
	cost_price NUMERIC(12, 2) NOT NULL, 
	received_date DATE NOT NULL, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(item_id) REFERENCES items (id), 
	FOREIGN KEY(warehouse_id) REFERENCES warehouses (id)
);

CREATE INDEX ix_inventory_lots_id ON inventory_lots (id);

CREATE TABLE employees (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	dept_id INTEGER, 
	position VARCHAR(100), 
	id_card VARCHAR(20), 
	birthday DATE, 
	phone VARCHAR(20), 
	mobile VARCHAR(20), 
	email VARCHAR(100), 
	hire_date DATE, 
	leave_date DATE, 
	salary NUMERIC(12, 2), 
	commission_rate NUMERIC(5, 4), 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	password_hash VARCHAR(255), 
	role VARCHAR(20), 
	is_superuser BOOLEAN, 
	last_login_at TIMESTAMP WITHOUT TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code), 
	FOREIGN KEY(dept_id) REFERENCES departments (id)
);

CREATE INDEX ix_employees_id ON employees (id);

CREATE TABLE purchase_orders (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	po_no VARCHAR(20) NOT NULL, 
	vendor_id INTEGER NOT NULL, 
	order_date DATE NOT NULL, 
	expected_date DATE, 
	subtotal NUMERIC(12, 2), 
	tax NUMERIC(12, 2), 
	total NUMERIC(12, 2), 
	status VARCHAR(20), 
	note TEXT, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (po_no), 
	FOREIGN KEY(vendor_id) REFERENCES vendors (id)
);

CREATE INDEX ix_purchase_orders_id ON purchase_orders (id);

CREATE TABLE bom_items (
	id SERIAL NOT NULL, 
	bom_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	qty_per_unit NUMERIC(12, 4) NOT NULL, 
	is_component BOOLEAN, 
	scrap_rate NUMERIC(5, 4), 
	PRIMARY KEY (id), 
	FOREIGN KEY(bom_id) REFERENCES boms (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_bom_items_id ON bom_items (id);

CREATE TABLE work_orders (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	wo_no VARCHAR(20) NOT NULL, 
	bom_id INTEGER, 
	product_id INTEGER NOT NULL, 
	qty NUMERIC(12, 2) NOT NULL, 
	status VARCHAR(20), 
	planned_start DATE, 
	planned_end DATE, 
	actual_start DATE, 
	actual_end DATE, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (wo_no), 
	FOREIGN KEY(bom_id) REFERENCES boms (id), 
	FOREIGN KEY(product_id) REFERENCES items (id)
);

CREATE INDEX ix_work_orders_id ON work_orders (id);

CREATE TABLE inventory_adjustments (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	adj_no VARCHAR(20) NOT NULL, 
	warehouse_id INTEGER NOT NULL, 
	reason VARCHAR(100), 
	status VARCHAR(20), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	approved_at TIMESTAMP WITHOUT TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (adj_no), 
	FOREIGN KEY(warehouse_id) REFERENCES warehouses (id)
);

CREATE INDEX ix_inventory_adjustments_id ON inventory_adjustments (id);

CREATE TABLE stock_takes (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	st_no VARCHAR(20) NOT NULL, 
	warehouse_id INTEGER NOT NULL, 
	count_date DATE NOT NULL, 
	status VARCHAR(20), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	completed_at TIMESTAMP WITHOUT TIME ZONE, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (st_no), 
	FOREIGN KEY(warehouse_id) REFERENCES warehouses (id)
);

CREATE INDEX ix_stock_takes_id ON stock_takes (id);

CREATE TABLE customers (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	type VARCHAR(20) NOT NULL, 
	site VARCHAR(10), 
	parent_id INTEGER, 
	channel_id INTEGER, 
	collection_target_id INTEGER, 
	payment_method VARCHAR(50), 
	billing_target VARCHAR(100), 
	contact_person VARCHAR(100), 
	phone VARCHAR(20), 
	mobile VARCHAR(20), 
	email VARCHAR(100), 
	invoice_address TEXT, 
	invoice_zip VARCHAR(10), 
	delivery_address TEXT, 
	delivery_zip VARCHAR(10), 
	area VARCHAR(50), 
	tax_id VARCHAR(20), 
	birthday DATE, 
	customer_type VARCHAR(50), 
	industry VARCHAR(50), 
	credit_limit INTEGER, 
	note TEXT, 
	sales_emp_id INTEGER, 
	tier_id INTEGER, 
	points INTEGER, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code), 
	FOREIGN KEY(parent_id) REFERENCES customers (id), 
	FOREIGN KEY(channel_id) REFERENCES channels (id), 
	FOREIGN KEY(collection_target_id) REFERENCES collection_targets (id), 
	FOREIGN KEY(sales_emp_id) REFERENCES employees (id), 
	FOREIGN KEY(tier_id) REFERENCES member_tiers (id)
);

CREATE INDEX ix_customers_id ON customers (id);

CREATE TABLE commissions (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	settlement_id INTEGER NOT NULL, 
	employee_id INTEGER NOT NULL, 
	commission_rate NUMERIC(5, 4) NOT NULL, 
	profit_amount NUMERIC(12, 2) NOT NULL, 
	commission_amount NUMERIC(12, 2) NOT NULL, 
	settled BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(settlement_id) REFERENCES settlements (id), 
	FOREIGN KEY(employee_id) REFERENCES employees (id)
);

CREATE INDEX ix_commissions_id ON commissions (id);

CREATE TABLE accounts_receivable (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	ar_no VARCHAR(20) NOT NULL, 
	source_type VARCHAR(20), 
	source_id INTEGER, 
	collection_target_id INTEGER NOT NULL, 
	settlement_id INTEGER, 
	amount NUMERIC(12, 2) NOT NULL, 
	paid_amount NUMERIC(12, 2), 
	status VARCHAR(20), 
	due_date DATE, 
	paid_at TIMESTAMP WITHOUT TIME ZONE, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (ar_no), 
	FOREIGN KEY(collection_target_id) REFERENCES collection_targets (id), 
	FOREIGN KEY(settlement_id) REFERENCES settlements (id)
);

CREATE INDEX ix_accounts_receivable_id ON accounts_receivable (id);

COMMENT ON COLUMN accounts_receivable.source_type IS 'ORDER / SETTLEMENT / POS / RETURN（SSOT §5.7）';

COMMENT ON COLUMN accounts_receivable.source_id IS '對應來源單據 ID（orders.id / settlements.id / pos_transactions.id / order_returns.id）';

CREATE TABLE purchase_order_items (
	id SERIAL NOT NULL, 
	purchase_order_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	qty NUMERIC(12, 2) NOT NULL, 
	unit_price NUMERIC(12, 2) NOT NULL, 
	subtotal NUMERIC(12, 2) NOT NULL, 
	received_qty NUMERIC(12, 2), 
	PRIMARY KEY (id), 
	FOREIGN KEY(purchase_order_id) REFERENCES purchase_orders (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_purchase_order_items_id ON purchase_order_items (id);

CREATE TABLE work_order_items (
	id SERIAL NOT NULL, 
	work_order_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	qty NUMERIC(12, 2) NOT NULL, 
	type VARCHAR(20) NOT NULL, 
	cost_price NUMERIC(12, 2), 
	PRIMARY KEY (id), 
	FOREIGN KEY(work_order_id) REFERENCES work_orders (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_work_order_items_id ON work_order_items (id);

CREATE TABLE inventory_adjustment_items (
	id SERIAL NOT NULL, 
	adjustment_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	qty_change NUMERIC(12, 2) NOT NULL, 
	reason TEXT, 
	PRIMARY KEY (id), 
	FOREIGN KEY(adjustment_id) REFERENCES inventory_adjustments (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_inventory_adjustment_items_id ON inventory_adjustment_items (id);

CREATE TABLE stock_take_items (
	id SERIAL NOT NULL, 
	stock_take_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	system_qty NUMERIC(12, 2) NOT NULL, 
	counted_qty NUMERIC(12, 2), 
	variance NUMERIC(12, 2), 
	note TEXT, 
	PRIMARY KEY (id), 
	FOREIGN KEY(stock_take_id) REFERENCES stock_takes (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_stock_take_items_id ON stock_take_items (id);

CREATE TABLE pos_shifts (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	shift_no VARCHAR(20) NOT NULL, 
	opened_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	opened_by INTEGER, 
	closed_at TIMESTAMP WITHOUT TIME ZONE, 
	closed_by INTEGER, 
	opening_amount NUMERIC(12, 2), 
	closing_amount NUMERIC(12, 2), 
	status VARCHAR(10), 
	note VARCHAR(500), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(opened_by) REFERENCES employees (id), 
	FOREIGN KEY(closed_by) REFERENCES employees (id)
);

CREATE INDEX ix_pos_shifts_id ON pos_shifts (id);

CREATE TABLE attendances (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	employee_id INTEGER NOT NULL, 
	work_date VARCHAR(10) NOT NULL, 
	clock_in_time TIME WITHOUT TIME ZONE, 
	clock_in_lat VARCHAR(20), 
	clock_in_lng VARCHAR(20), 
	clock_in_photo VARCHAR(500), 
	clock_out_time TIME WITHOUT TIME ZONE, 
	clock_out_lat VARCHAR(20), 
	clock_out_lng VARCHAR(20), 
	clock_out_photo VARCHAR(500), 
	status VARCHAR(20), 
	note VARCHAR(200), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(employee_id) REFERENCES employees (id)
);

CREATE INDEX ix_attendances_id ON attendances (id);

CREATE TABLE leave_requests (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	employee_id INTEGER NOT NULL, 
	leave_type VARCHAR(20) NOT NULL, 
	reason TEXT, 
	start_date VARCHAR(10) NOT NULL, 
	start_half VARCHAR(5), 
	end_date VARCHAR(10) NOT NULL, 
	end_half VARCHAR(5), 
	hours INTEGER, 
	status VARCHAR(20), 
	agent_emp_id INTEGER, 
	approved_by INTEGER, 
	approved_at TIMESTAMP WITHOUT TIME ZONE, 
	approve_note VARCHAR(200), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(employee_id) REFERENCES employees (id), 
	FOREIGN KEY(agent_emp_id) REFERENCES employees (id), 
	FOREIGN KEY(approved_by) REFERENCES employees (id)
);

CREATE INDEX ix_leave_requests_id ON leave_requests (id);

CREATE TABLE fiscal_periods (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	year INTEGER NOT NULL, 
	month INTEGER NOT NULL, 
	closed_at TIMESTAMP WITHOUT TIME ZONE, 
	closed_by INTEGER, 
	notes TEXT, 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(closed_by) REFERENCES employees (id)
);

CREATE INDEX ix_fiscal_periods_id ON fiscal_periods (id);

CREATE TABLE inventory (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	warehouse_id INTEGER NOT NULL, 
	customer_id INTEGER, 
	available_qty INTEGER, 
	consignment_qty INTEGER, 
	allocated_qty INTEGER, 
	on_order_qty INTEGER, 
	location VARCHAR(50), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(item_id) REFERENCES items (id), 
	FOREIGN KEY(warehouse_id) REFERENCES warehouses (id), 
	FOREIGN KEY(customer_id) REFERENCES customers (id)
);

CREATE INDEX ix_inventory_id ON inventory (id);

CREATE UNIQUE INDEX uq_inventory_customer ON inventory (item_id, warehouse_id, customer_id) WHERE customer_id IS NOT NULL;

CREATE UNIQUE INDEX uq_inventory_hq ON inventory (item_id, warehouse_id) WHERE customer_id IS NULL;

CREATE TABLE consignment_risk_settings (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	customer_id INTEGER NOT NULL, 
	consignment_limit NUMERIC(12, 2) NOT NULL, 
	max_unsettled_months INTEGER, 
	safety_days_limit INTEGER, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(customer_id) REFERENCES customers (id)
);

CREATE INDEX ix_consignment_risk_settings_id ON consignment_risk_settings (id);

CREATE TABLE orders (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	order_no VARCHAR(50) NOT NULL, 
	type VARCHAR(20), 
	order_date DATE NOT NULL, 
	accounting_date DATE, 
	employee_id VARCHAR(50), 
	department_id VARCHAR(50), 
	project_id VARCHAR(50), 
	remarks TEXT, 
	channel_id INTEGER NOT NULL, 
	collection_target_id INTEGER NOT NULL, 
	payment_method_id INTEGER NOT NULL, 
	customer_id INTEGER, 
	customer_name VARCHAR(100), 
	customer_phone VARCHAR(20), 
	customer_address VARCHAR(500), 
	subtotal NUMERIC(12, 2), 
	tax NUMERIC(12, 2), 
	total NUMERIC(12, 2), 
	status VARCHAR(30), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (order_no), 
	FOREIGN KEY(channel_id) REFERENCES channels (id), 
	FOREIGN KEY(collection_target_id) REFERENCES collection_targets (id), 
	FOREIGN KEY(payment_method_id) REFERENCES payment_methods (id), 
	FOREIGN KEY(customer_id) REFERENCES customers (id)
);

CREATE INDEX ix_orders_id ON orders (id);

COMMENT ON COLUMN orders.type IS 'OrderType 枚舉：DIRECT_SALE / CONSIGNMENT_SHIPMENT';

COMMENT ON COLUMN orders.status IS 'OrderStatus 枚舉：DRAFT/HOLD_RISK/SHIPPED/SETTLED/CANCELLED';

CREATE TABLE consignments (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	consignment_no VARCHAR(20) NOT NULL, 
	channel_id INTEGER NOT NULL, 
	collection_target_id INTEGER NOT NULL, 
	payment_method_id INTEGER NOT NULL, 
	agent_id INTEGER NOT NULL, 
	agent_name VARCHAR(100), 
	ship_date DATE NOT NULL, 
	settle_month VARCHAR(7), 
	status VARCHAR(20), 
	fg_ret VARCHAR(1), 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (consignment_no), 
	FOREIGN KEY(channel_id) REFERENCES channels (id), 
	FOREIGN KEY(collection_target_id) REFERENCES collection_targets (id), 
	FOREIGN KEY(payment_method_id) REFERENCES payment_methods (id), 
	FOREIGN KEY(agent_id) REFERENCES customers (id)
);

CREATE INDEX ix_consignments_id ON consignments (id);

CREATE TABLE pos_transactions (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	shift_id INTEGER, 
	transaction_no VARCHAR(30) NOT NULL, 
	transaction_type VARCHAR(10), 
	channel_id INTEGER NOT NULL, 
	payment_method_id INTEGER NOT NULL, 
	customer_id INTEGER, 
	customer_name VARCHAR(100), 
	subtotal NUMERIC(12, 2), 
	tax NUMERIC(12, 2), 
	total NUMERIC(12, 2), 
	refund_of_id INTEGER, 
	items_json TEXT, 
	status VARCHAR(10), 
	terminal_no VARCHAR(30), 
	employee_id INTEGER, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	FOREIGN KEY(shift_id) REFERENCES pos_shifts (id), 
	UNIQUE (transaction_no), 
	FOREIGN KEY(channel_id) REFERENCES channels (id), 
	FOREIGN KEY(payment_method_id) REFERENCES payment_methods (id), 
	FOREIGN KEY(customer_id) REFERENCES customers (id), 
	FOREIGN KEY(refund_of_id) REFERENCES pos_transactions (id), 
	FOREIGN KEY(employee_id) REFERENCES employees (id)
);

CREATE INDEX ix_pos_transactions_id ON pos_transactions (id);

CREATE TABLE order_items (
	id SERIAL NOT NULL, 
	order_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	item_code VARCHAR(20), 
	item_name VARCHAR(255), 
	specification VARCHAR(255), 
	qty NUMERIC(10, 2) NOT NULL, 
	unit_price NUMERIC(12, 2) NOT NULL, 
	subtotal NUMERIC(12, 2) NOT NULL, 
	tax NUMERIC(10, 2), 
	fifo_lot_id INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY(order_id) REFERENCES orders (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_order_items_id ON order_items (id);

COMMENT ON COLUMN order_items.tax IS '5%% 營業稅乘數（subtotal × tax = 稅額）';

CREATE TABLE order_returns (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	return_number VARCHAR(50) NOT NULL, 
	original_order_id INTEGER NOT NULL, 
	return_date DATE NOT NULL, 
	reason TEXT, 
	refund_amount NUMERIC(12, 2) NOT NULL, 
	status VARCHAR(30) NOT NULL, 
	warehouse_id INTEGER, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (return_number), 
	FOREIGN KEY(original_order_id) REFERENCES orders (id), 
	FOREIGN KEY(warehouse_id) REFERENCES warehouses (id)
);

CREATE INDEX ix_order_returns_id ON order_returns (id);

CREATE INDEX ix_order_returns_tenant_id ON order_returns (tenant_id);

CREATE INDEX ix_order_returns_original_order_id ON order_returns (original_order_id);

COMMENT ON COLUMN order_returns.original_order_id IS '對應原銷貨單（必須是 SHIPPED 狀態）';

COMMENT ON COLUMN order_returns.reason IS '退貨原因（瑕疵/尺寸不合/客戶改變心意...）';

COMMENT ON COLUMN order_returns.status IS 'ReturnStatus 枚舉：PENDING/COMPLETED/CANCELLED';

COMMENT ON COLUMN order_returns.warehouse_id IS '退回倉庫（通常為 QC 倉，等待品檢）';

CREATE TABLE order_quotes (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	quote_number VARCHAR(50) NOT NULL, 
	customer_id INTEGER, 
	channel_id INTEGER NOT NULL, 
	quote_date DATE NOT NULL, 
	valid_until DATE, 
	status VARCHAR(30) NOT NULL, 
	total_amount NUMERIC(12, 2), 
	converted_order_id INTEGER, 
	is_active BOOLEAN, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (quote_number), 
	FOREIGN KEY(customer_id) REFERENCES customers (id), 
	FOREIGN KEY(channel_id) REFERENCES channels (id), 
	FOREIGN KEY(converted_order_id) REFERENCES orders (id)
);

CREATE INDEX ix_order_quotes_tenant_id ON order_quotes (tenant_id);

CREATE INDEX ix_order_quotes_id ON order_quotes (id);

COMMENT ON COLUMN order_quotes.customer_id IS '報價客戶（可空 = 開放式報價）';

COMMENT ON COLUMN order_quotes.channel_id IS '通路代號（與後續轉單的 orders.channel_id 一致）';

COMMENT ON COLUMN order_quotes.valid_until IS '報價有效期限（預設 30 天，逾期自動 EXPIRED）';

COMMENT ON COLUMN order_quotes.status IS 'QuoteStatus 枚舉：PENDING/ACCEPTED/EXPIRED/CONVERTED';

COMMENT ON COLUMN order_quotes.total_amount IS '含稅總計（quote_items.subtotal 加總後 × 1.05）';

COMMENT ON COLUMN order_quotes.converted_order_id IS '已轉銷貨單的 ID（CONVERTED 狀態後填入）';

CREATE TABLE consignment_items (
	id SERIAL NOT NULL, 
	consignment_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	item_code VARCHAR(20), 
	item_name VARCHAR(255), 
	qty NUMERIC(10, 2) NOT NULL, 
	agreed_price NUMERIC(12, 2), 
	cost_price NUMERIC(12, 2), 
	fifo_lot_id INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY(consignment_id) REFERENCES consignments (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_consignment_items_id ON consignment_items (id);

CREATE TABLE settlement_items (
	id SERIAL NOT NULL, 
	settlement_id INTEGER NOT NULL, 
	consignment_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	qty NUMERIC(10, 2) NOT NULL, 
	unit_price NUMERIC(12, 2) NOT NULL, 
	subtotal NUMERIC(12, 2) NOT NULL, 
	settled_qty NUMERIC(10, 2), 
	settled_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(settlement_id) REFERENCES settlements (id) ON DELETE CASCADE, 
	FOREIGN KEY(consignment_id) REFERENCES consignments (id), 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_settlement_items_id ON settlement_items (id);

CREATE TABLE vouchers (
	id SERIAL NOT NULL, 
	tenant_id INTEGER NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	customer_id INTEGER, 
	promotion_id INTEGER, 
	type VARCHAR(20) NOT NULL, 
	value NUMERIC(12, 2) NOT NULL, 
	min_purchase NUMERIC(12, 2), 
	valid_from DATE, 
	valid_until DATE, 
	is_used BOOLEAN, 
	used_at TIMESTAMP WITHOUT TIME ZONE, 
	used_order_id INTEGER, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(), 
	PRIMARY KEY (id), 
	FOREIGN KEY(tenant_id) REFERENCES tenants (id), 
	UNIQUE (code), 
	FOREIGN KEY(customer_id) REFERENCES customers (id), 
	FOREIGN KEY(promotion_id) REFERENCES promotions (id), 
	FOREIGN KEY(used_order_id) REFERENCES orders (id)
);

CREATE INDEX ix_vouchers_id ON vouchers (id);

CREATE TABLE return_items (
	id SERIAL NOT NULL, 
	return_id INTEGER NOT NULL, 
	order_item_id INTEGER NOT NULL, 
	qty INTEGER NOT NULL, 
	unit_price NUMERIC(10, 2) NOT NULL, 
	subtotal NUMERIC(12, 2) NOT NULL, 
	fifo_lot_id INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY(return_id) REFERENCES order_returns (id) ON DELETE CASCADE, 
	FOREIGN KEY(order_item_id) REFERENCES order_items (id), 
	FOREIGN KEY(fifo_lot_id) REFERENCES inventory_lots (id)
);

CREATE INDEX ix_return_items_id ON return_items (id);

CREATE INDEX ix_return_items_return_id ON return_items (return_id);

COMMENT ON COLUMN return_items.order_item_id IS '對應原銷貨明細（鎖定原售價）';

COMMENT ON COLUMN return_items.qty IS '退貨數量（> 0）';

COMMENT ON COLUMN return_items.unit_price IS '退貨單價（從 order_items.unit_price 帶入）';

COMMENT ON COLUMN return_items.subtotal IS '退款小計 = qty × unit_price';

COMMENT ON COLUMN return_items.fifo_lot_id IS 'FIFO 回補批次（NULL = 尚未指定）';

CREATE TABLE quote_items (
	id SERIAL NOT NULL, 
	quote_id INTEGER NOT NULL, 
	item_id INTEGER NOT NULL, 
	qty INTEGER NOT NULL, 
	unit_price NUMERIC(10, 2) NOT NULL, 
	subtotal NUMERIC(12, 2) NOT NULL, 
	tax NUMERIC(10, 2), 
	PRIMARY KEY (id), 
	FOREIGN KEY(quote_id) REFERENCES order_quotes (id) ON DELETE CASCADE, 
	FOREIGN KEY(item_id) REFERENCES items (id)
);

CREATE INDEX ix_quote_items_quote_id ON quote_items (quote_id);

CREATE INDEX ix_quote_items_id ON quote_items (id);

COMMENT ON COLUMN quote_items.unit_price IS '報價單價';

COMMENT ON COLUMN quote_items.subtotal IS '= qty × unit_price';

COMMENT ON COLUMN quote_items.tax IS '5%% 營業稅乘數（與 order_items.tax 一致）';

