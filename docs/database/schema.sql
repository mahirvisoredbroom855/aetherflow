BEGIN;

-- ============================================================
-- ENUM TYPES (safe to re-run)
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dataset_status') THEN
    CREATE TYPE dataset_status AS ENUM ('uploaded', 'processing', 'completed', 'failed');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_type') THEN
    CREATE TYPE job_type AS ENUM ('etl', 'ml_inference');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status') THEN
    CREATE TYPE job_status AS ENUM ('queued', 'processing', 'succeeded', 'failed');
  END IF;
END$$;

-- ============================================================
-- DATASETS
-- ============================================================

CREATE TABLE IF NOT EXISTS datasets (
  id BIGSERIAL PRIMARY KEY,

  department VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,

  uploader_id BIGINT NOT NULL REFERENCES users(id),

  file_type VARCHAR(20) NOT NULL,
  s3_bucket VARCHAR(100) NOT NULL,
  s3_key VARCHAR(500) NOT NULL,

  file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes >= 0),
  row_count BIGINT NULL CHECK (row_count IS NULL OR row_count >= 0),

  status dataset_status NOT NULL DEFAULT 'uploaded',

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- "Future-proof but strict enough": enforce MVP departments here too
ALTER TABLE datasets
  ADD CONSTRAINT datasets_department_check
  CHECK (department IN ('sales','supply','finance'));

-- Indexes for common patterns
CREATE INDEX IF NOT EXISTS idx_datasets_department_created_at
  ON datasets(department, created_at);

CREATE INDEX IF NOT EXISTS idx_datasets_uploader_id
  ON datasets(uploader_id);

CREATE INDEX IF NOT EXISTS idx_datasets_status
  ON datasets(status);

-- ============================================================
-- JOBS (ETL + ML lifecycle)
-- ============================================================

CREATE TABLE IF NOT EXISTS jobs (
  id BIGSERIAL PRIMARY KEY,

  dataset_id BIGINT NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,

  job_type job_type NOT NULL,
  status job_status NOT NULL DEFAULT 'queued',

  queue_message_id VARCHAR(255) NULL,

  attempts INT NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  max_attempts INT NOT NULL DEFAULT 3 CHECK (max_attempts >= 1),

  error_message TEXT NULL,
  error_traceback TEXT NULL,

  started_at TIMESTAMPTZ NULL,
  completed_at TIMESTAMPTZ NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_jobs_dataset_id_job_type
  ON jobs(dataset_id, job_type);

CREATE INDEX IF NOT EXISTS idx_jobs_status_created_at
  ON jobs(status, created_at);

CREATE INDEX IF NOT EXISTS idx_jobs_queue_message_id
  ON jobs(queue_message_id);

-- ============================================================
-- RESULTS (JSONB outputs per department)
-- ============================================================

CREATE TABLE IF NOT EXISTS results (
  id BIGSERIAL PRIMARY KEY,

  dataset_id BIGINT NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,

  department VARCHAR(50) NOT NULL,
  result_type VARCHAR(100) NOT NULL,

  payload JSONB NOT NULL,
  metadata JSONB NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE results
  ADD CONSTRAINT results_department_check
  CHECK (department IN ('sales','supply','finance'));

CREATE INDEX IF NOT EXISTS idx_results_dataset_id_result_type
  ON results(dataset_id, result_type);

CREATE INDEX IF NOT EXISTS idx_results_department_created_at
  ON results(department, created_at DESC);

-- JSONB index for querying inside payload if needed later
CREATE INDEX IF NOT EXISTS idx_results_payload_gin
  ON results USING GIN (payload);

COMMIT;
