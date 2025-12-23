# AetherFlow — Database Schema Design (Department-Aware)

**Author:** Shahriyar Ahmed Mahir  
**Project:** AetherFlow (Retail Intelligence MVP)  
**Database:** PostgreSQL (Local: Docker Compose / Prod: AWS RDS)  
**Multi-tenancy model:** Column-based department isolation (RBAC enforced in API layer)

---

## 1) Goals & Requirements

AetherFlow requires a schema that supports:

- **Department-aware isolation**: Sales, Supply Chain, Finance (plus Admin)
- **Dataset tracking**: Who uploaded what, where it lives (S3), size, type, lifecycle status
- **Job lifecycle tracking**: ETL and ML jobs, retries, idempotency, error debugging
- **Results storage**: Department-specific insights stored flexibly while remaining queryable
- **Operational queries**: Monitoring dashboards, “what’s processing?”, “what failed?”, “latest results?”

---

## 2) Multi-Tenancy (Department Isolation) Strategy

### Approach: Column-based multi-tenancy
- Every record that is department-scoped contains `department` (e.g., `datasets.department`, `results.department`).
- Application layer (FastAPI RBAC middleware) enforces:
  - Non-admin users can only access rows where `department = current_user.department`.
  - Admin can access all departments.

**Pros**
- Simple, fast to implement, strong performance with proper indexing.

**Cons**
- Risk of cross-department data leaks if filters are missed.
- **Mitigation**: Central RBAC middleware + service-level query helpers (never query without dept filter).

**Post-MVP upgrade**
- PostgreSQL Row-Level Security (RLS) policies for defense-in-depth.

**Contract (must-follow)**
- Every department-scoped API endpoint must apply:
  - `WHERE department = :current_user_department`
  - or `WHERE dataset_id IN (SELECT id FROM datasets WHERE department = :current_user_department)`

---

## 3) Table Specifications

> Note: `users` already exists from Phase 2.2. We verify it, but do not modify it here.

### 3.1 `users` (Existing)
Purpose: Auth identity, RBAC roles, and department assignment.

**Required columns:**
- `id` (PK)
- `email` (unique, indexed)
- `password_hash`
- `role` (enum: `sales`, `supply`, `finance`, `admin`)
- `department` (string; typically mirrors role for MVP)
- `is_active` (boolean)
- `created_at`, `updated_at`

---

### 3.2 `datasets`
Purpose: Track every uploaded dataset, where it lives in S3, lifecycle status, and ownership.

**Columns:**
- `id` INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY
- `department` VARCHAR(50) NOT NULL
- `name` VARCHAR(255) NOT NULL
- `description` TEXT NULL
- `uploader_id` INTEGER NOT NULL REFERENCES users(id)
- `file_type` VARCHAR(20) NOT NULL (e.g., `csv`, `json`)
- `s3_bucket` VARCHAR(100) NOT NULL
- `s3_key` VARCHAR(500) NOT NULL
- `file_size_bytes` BIGINT NOT NULL
- `row_count` INTEGER NULL (filled after ETL)
- `status` VARCHAR(20) NOT NULL DEFAULT 'uploaded'
- `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()
- `updated_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**Constraints:**
- `CHECK (status IN ('uploaded', 'processing', 'completed', 'failed'))`
- `CHECK (department IN ('sales', 'supply', 'finance'))`

**Indexes:**
- `CREATE INDEX datasets_dept_created_idx ON datasets (department, created_at DESC);`
- `CREATE INDEX datasets_uploader_idx ON datasets (uploader_id);`
- `CREATE INDEX datasets_status_idx ON datasets (status);`

---

### 3.3 `jobs`
Purpose: Represent the asynchronous pipeline lifecycle per dataset. Jobs power monitoring and debugging.

**Columns:**
- `id` INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY
- `dataset_id` INTEGER NOT NULL REFERENCES datasets(id) ON DELETE CASCADE
- `job_type` VARCHAR(30) NOT NULL
- `status` VARCHAR(20) NOT NULL DEFAULT 'queued'
- `queue_message_id` VARCHAR(255) NULL
- `attempts` INTEGER NOT NULL DEFAULT 0
- `max_attempts` INTEGER NOT NULL DEFAULT 3
- `error_message` TEXT NULL
- `error_traceback` TEXT NULL
- `started_at` TIMESTAMPTZ NULL
- `completed_at` TIMESTAMPTZ NULL
- `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()
- `updated_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**Constraints:**
- `CHECK (job_type IN ('etl', 'ml_inference'))`
- `CHECK (status IN ('queued', 'processing', 'succeeded', 'failed'))`
- `CHECK (attempts >= 0 AND max_attempts >= 1)`

**Indexes:**
- `CREATE INDEX jobs_dataset_type_idx ON jobs (dataset_id, job_type);`
- `CREATE INDEX jobs_status_created_idx ON jobs (status, created_at DESC);`
- `CREATE INDEX jobs_queue_msg_idx ON jobs (queue_message_id);`

---

### 3.4 `results`
Purpose: Store insights produced from ETL and ML inference. Uses JSONB for flexibility.

**Columns:**
- `id` INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY
- `dataset_id` INTEGER NOT NULL REFERENCES datasets(id) ON DELETE CASCADE
- `department` VARCHAR(50) NOT NULL
- `result_type` VARCHAR(100) NOT NULL
- `payload` JSONB NOT NULL
- `metadata` JSONB NULL
- `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()

**Indexes:**
- `CREATE INDEX results_dataset_type_idx ON results (dataset_id, result_type);`
- `CREATE INDEX results_dept_created_idx ON results (department, created_at DESC);`
- `CREATE INDEX results_payload_gin_idx ON results USING GIN (payload);`

---

## 4) Entity-Relationship Summary



- `users (1) → (N) datasets`
- `datasets (1) → (N) jobs`
- `datasets (1) → (N) results`

**Cardinality:**
- A user uploads many datasets.
- A dataset creates multiple jobs (ETL first, then ML).
- A dataset can produce multiple results (ETL summary + department insight).

---

## 5) Data Lifecycle / Retention Policy (MVP + Future)

### MVP rules
- **Raw S3 files**: Keep 90 days (cost control).
- **DB records**: Keep indefinitely for MVP.
- **Cleanup behavior**: Deleting a dataset automatically deletes related jobs and results via `ON DELETE CASCADE`.

---

## 6) Common Query Patterns

### Q1: Latest datasets for a department
```sql
SELECT *
FROM datasets
WHERE department = $1
ORDER BY created_at DESC
LIMIT 20;