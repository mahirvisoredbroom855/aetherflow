BEGIN;

-- ============================================================
-- USERS (3 dept users + 1 admin)
-- password_hash values are placeholders for local dev
-- ============================================================

INSERT INTO users (email, password_hash, role, department, is_active)
VALUES
  ('sales.manager@aetherflow.dev',  'dev_hash_sales',  'sales',   'sales',   true),
  ('supply.analyst@aetherflow.dev', 'dev_hash_supply', 'supply',  'supply',  true),
  ('finance.analyst@aetherflow.dev','dev_hash_fin',    'finance', 'finance', true),
  ('admin@aetherflow.dev',          'dev_hash_admin',  'admin',   'sales',   true)
ON CONFLICT (email) DO NOTHING;

-- Capture user IDs for FK usage
WITH u AS (
  SELECT id, email FROM users
)
SELECT * FROM u;

-- ============================================================
-- DATASETS (6 datasets: 2 per department)
-- ============================================================

-- Sales datasets
INSERT INTO datasets
(department, name, description, uploader_id, file_type, s3_bucket, s3_key, file_size_bytes, row_count, status)
SELECT
  'sales',
  'Sales Transactions - Nov',
  'Transaction records for November sales.',
  u.id,
  'csv',
  'aetherflow-raw-dev',
  'sales/2025-11/sales_transactions_nov.csv',
  48213,
  1250,
  'completed'
FROM users u WHERE u.email = 'sales.manager@aetherflow.dev';

INSERT INTO datasets
(department, name, description, uploader_id, file_type, s3_bucket, s3_key, file_size_bytes, row_count, status)
SELECT
  'sales',
  'Sales Transactions - Dec',
  'Transaction records for December sales.',
  u.id,
  'csv',
  'aetherflow-raw-dev',
  'sales/2025-12/sales_transactions_dec.csv',
  50102,
  NULL,
  'processing'
FROM users u WHERE u.email = 'sales.manager@aetherflow.dev';

-- Supply datasets
INSERT INTO datasets
(department, name, description, uploader_id, file_type, s3_bucket, s3_key, file_size_bytes, row_count, status)
SELECT
  'supply',
  'Inventory Snapshot - Warehouse A',
  'SKU inventory snapshot for Warehouse A.',
  u.id,
  'csv',
  'aetherflow-raw-dev',
  'supply/warehouse-a/inventory_snapshot.csv',
  22110,
  980,
  'completed'
FROM users u WHERE u.email = 'supply.analyst@aetherflow.dev';

INSERT INTO datasets
(department, name, description, uploader_id, file_type, s3_bucket, s3_key, file_size_bytes, row_count, status)
SELECT
  'supply',
  'Inventory Snapshot - Warehouse B',
  'SKU inventory snapshot for Warehouse B.',
  u.id,
  'csv',
  'aetherflow-raw-dev',
  'supply/warehouse-b/inventory_snapshot.csv',
  21800,
  950,
  'failed'
FROM users u WHERE u.email = 'supply.analyst@aetherflow.dev';

-- Finance datasets
INSERT INTO datasets
(department, name, description, uploader_id, file_type, s3_bucket, s3_key, file_size_bytes, row_count, status)
SELECT
  'finance',
  'Expense Ledger - Q4',
  'Expense ledger for Q4 across vendors and categories.',
  u.id,
  'csv',
  'aetherflow-raw-dev',
  'finance/q4/expense_ledger.csv',
  61200,
  2100,
  'completed'
FROM users u WHERE u.email = 'finance.analyst@aetherflow.dev';

INSERT INTO datasets
(department, name, description, uploader_id, file_type, s3_bucket, s3_key, file_size_bytes, row_count, status)
SELECT
  'finance',
  'Expense Ledger - Q4 (Late Upload)',
  'Late upload; pending ETL.',
  u.id,
  'csv',
  'aetherflow-raw-dev',
  'finance/q4/expense_ledger_late.csv',
  59010,
  NULL,
  'uploaded'
FROM users u WHERE u.email = 'finance.analyst@aetherflow.dev';

-- ============================================================
-- JOBS (12 jobs: 2 per dataset: ETL then ML)
-- We'll insert jobs using dataset names to resolve dataset_id.
-- ============================================================

-- Helper: create ETL + ML jobs for each dataset
-- Sales Nov (completed)
INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at, completed_at)
SELECT d.id, 'etl', 'succeeded', 1, 3, now() - interval '2 days', now() - interval '2 days' + interval '3 minutes'
FROM datasets d WHERE d.name = 'Sales Transactions - Nov';

INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at, completed_at)
SELECT d.id, 'ml_inference', 'succeeded', 1, 3, now() - interval '2 days' + interval '4 minutes', now() - interval '2 days' + interval '6 minutes'
FROM datasets d WHERE d.name = 'Sales Transactions - Nov';

-- Sales Dec (processing)
INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at)
SELECT d.id, 'etl', 'processing', 1, 3, now() - interval '10 minutes'
FROM datasets d WHERE d.name = 'Sales Transactions - Dec';

INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts)
SELECT d.id, 'ml_inference', 'queued', 0, 3
FROM datasets d WHERE d.name = 'Sales Transactions - Dec';

-- Supply A (completed)
INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at, completed_at)
SELECT d.id, 'etl', 'succeeded', 1, 3, now() - interval '1 day', now() - interval '1 day' + interval '2 minutes'
FROM datasets d WHERE d.name = 'Inventory Snapshot - Warehouse A';

INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at, completed_at)
SELECT d.id, 'ml_inference', 'succeeded', 1, 3, now() - interval '1 day' + interval '3 minutes', now() - interval '1 day' + interval '5 minutes'
FROM datasets d WHERE d.name = 'Inventory Snapshot - Warehouse A';

-- Supply B (failed ETL, ML queued never ran)
INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, error_message, error_traceback, started_at, completed_at)
SELECT d.id, 'etl', 'failed', 3, 3,
  'Schema validation failed: reorder_point column missing.',
  'Traceback... ValueError: missing column reorder_point',
  now() - interval '6 hours',
  now() - interval '6 hours' + interval '1 minute'
FROM datasets d WHERE d.name = 'Inventory Snapshot - Warehouse B';

INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts)
SELECT d.id, 'ml_inference', 'queued', 0, 3
FROM datasets d WHERE d.name = 'Inventory Snapshot - Warehouse B';

-- Finance Q4 (completed)
INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at, completed_at)
SELECT d.id, 'etl', 'succeeded', 1, 3, now() - interval '3 days', now() - interval '3 days' + interval '2 minutes'
FROM datasets d WHERE d.name = 'Expense Ledger - Q4';

INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts, started_at, completed_at)
SELECT d.id, 'ml_inference', 'succeeded', 1, 3, now() - interval '3 days' + interval '3 minutes', now() - interval '3 days' + interval '6 minutes'
FROM datasets d WHERE d.name = 'Expense Ledger - Q4';

-- Finance late upload (uploaded, ETL queued)
INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts)
SELECT d.id, 'etl', 'queued', 0, 3
FROM datasets d WHERE d.name = 'Expense Ledger - Q4 (Late Upload)';

INSERT INTO jobs (dataset_id, job_type, status, attempts, max_attempts)
SELECT d.id, 'ml_inference', 'queued', 0, 3
FROM datasets d WHERE d.name = 'Expense Ledger - Q4 (Late Upload)';

-- ============================================================
-- RESULTS (6 results: 1 per dataset)
-- payload is JSONB and varies by department.
-- ============================================================

-- Sales: forecast summary
INSERT INTO results (dataset_id, department, result_type, payload, metadata)
SELECT d.id, 'sales', 'sales_forecast',
  jsonb_build_object(
    'forecast_window_days', 7,
    'predicted_revenue', 184500.25,
    'top_categories', jsonb_build_array('Electronics','Home','Beauty'),
    'top_products', jsonb_build_array(
      jsonb_build_object('sku','SKU-111','predicted_units',420),
      jsonb_build_object('sku','SKU-205','predicted_units',390)
    )
  ),
  jsonb_build_object('model','baseline_timeseries_v1','generated_at', now())
FROM datasets d WHERE d.name = 'Sales Transactions - Nov';

-- Sales Dec (partial/in-progress placeholder)
INSERT INTO results (dataset_id, department, result_type, payload, metadata)
SELECT d.id, 'sales', 'etl_summary',
  jsonb_build_object('rows_processed', 600, 'invalid_rows', 3, 'status', 'processing'),
  jsonb_build_object('worker','etl_worker','generated_at', now())
FROM datasets d WHERE d.name = 'Sales Transactions - Dec';

-- Supply: inventory risk
INSERT INTO results (dataset_id, department, result_type, payload, metadata)
SELECT d.id, 'supply', 'inventory_risk',
  jsonb_build_object(
    'risk_horizon_days', 14,
    'at_risk_skus', jsonb_build_array(
      jsonb_build_object('sku','SKU-010','days_of_cover',3,'suggested_reorder_qty',120),
      jsonb_build_object('sku','SKU-044','days_of_cover',5,'suggested_reorder_qty',80)
    )
  ),
  jsonb_build_object('model','rules_v1','generated_at', now())
FROM datasets d WHERE d.name = 'Inventory Snapshot - Warehouse A';

-- Supply B (failed)
INSERT INTO results (dataset_id, department, result_type, payload, metadata)
SELECT d.id, 'supply', 'etl_summary',
  jsonb_build_object('status','failed','reason','missing column reorder_point'),
  jsonb_build_object('generated_at', now())
FROM datasets d WHERE d.name = 'Inventory Snapshot - Warehouse B';

-- Finance: anomalies
INSERT INTO results (dataset_id, department, result_type, payload, metadata)
SELECT d.id, 'finance', 'finance_anomalies',
  jsonb_build_object(
    'anomaly_count', 3,
    'anomalies', jsonb_build_array(
      jsonb_build_object('txn_id','TXN-9001','category','Marketing','amount', 19250.00,'z_score', 3.8),
      jsonb_build_object('txn_id','TXN-9014','category','IT','amount', 8700.00,'z_score', 3.2),
      jsonb_build_object('txn_id','TXN-9055','category','Travel','amount', 5400.00,'z_score', 3.1)
    )
  ),
  jsonb_build_object('model','isolation_forest_v1','generated_at', now())
FROM datasets d WHERE d.name = 'Expense Ledger - Q4';

-- Finance late upload (queued)
INSERT INTO results (dataset_id, department, result_type, payload, metadata)
SELECT d.id, 'finance', 'etl_summary',
  jsonb_build_object('status','queued'),
  jsonb_build_object('generated_at', now())
FROM datasets d WHERE d.name = 'Expense Ledger - Q4 (Late Upload)';

COMMIT;
