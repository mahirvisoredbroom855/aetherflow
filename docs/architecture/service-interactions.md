# Service Interactions — AetherFlow

This document defines the **service boundaries**, **interaction contracts**, and the **direction of data flow** between components in AetherFlow.

AetherFlow is a **department-aware, event-driven pipeline**:
- The **Frontend** is the user interface
- The **API Gateway** is the only HTTP entrypoint and enforces **JWT + RBAC**
- The **ETL Worker** transforms and validates uploaded datasets
- The **ML Worker** generates department-specific insights
- **PostgreSQL** stores system truth (users, datasets, jobs, insights)
- **S3** stores raw uploads
- **SQS** decouples and triggers async processing stages

---

## 1) System Interaction Diagram (Text-Based)

      ┌───────────────────────────────┐
      │        End User (Browser)      │
      └───────────────┬───────────────┘
                      │
                      v
      ┌───────────────────────────────┐
      │   Frontend Dashboard (Next.js) │
      │   - Auth UI                   │
      │   - Upload UI                 │
      │   - Jobs + Dashboards         │
      └───────────────┬───────────────┘
                      │  HTTPS (JWT in headers/cookies)
                      v
      ┌───────────────────────────────┐
      │     API Gateway (FastAPI)      │
      │  - Issue JWT                   │
      │  - Verify JWT                  │
      │  - Enforce RBAC                │
      │  - Upload orchestration        │
      └───────┬───────────┬───────────┘
              │           │
              v           v
   ┌────────────────┐   ┌──────────────────┐
   │ S3 (Raw Uploads)│   │ PostgreSQL (RDS) │
   │ - dept prefixes │   │ - users/roles    │
   │ - dataset files │   │ - datasets       │
   └───────┬────────┘   │ - jobs/status    │
           │            │ - insights/results│
           │            └──────────────────┘
           │
           v
   ┌──────────────────────────────────────┐
   │ SQS (Async Orchestration)            │
   │ - ETL Queue + ETL DLQ                │
   │ - ML Queue + ML DLQ                  │
   └───────────────┬──────────────────────┘
                   │
          ┌────────┴─────────┐
          │                  │
          v                  v
┌───────────────────┐   ┌───────────────────┐
│ ETL Worker         │   │ ML Worker          │
│ - consume ETL jobs  │   │ - consume ML jobs  │
│ - read raw from S3  │   │ - read clean data  │
│ - validate/transform│   │ - run inference    │
│ - write clean data  │   │ - write insights   │
│ - enqueue ML job    │   │ - update job state │
└───────┬───────────┘   └───────────┬───────┘
        │                           │
        v                           v
   ┌───────────────┐          ┌───────────────┐
   │ PostgreSQL (RDS)│         │ PostgreSQL (RDS)│
   │ - cleaned tables│         │ - insights      │
   │ - job status    │         │ - job status    │
   └───────────────┘          └───────────────┘

Observability:
- API Gateway logs → CloudWatch Logs
- Worker logs → CloudWatch Logs
- SQS metrics (queue depth, age) → CloudWatch

---

## 2) Service Responsibilities (Boundaries)

### Frontend Dashboard (Next.js)
**Does:**
- Renders login/register/upload/jobs/dashboard screens
- Sends authenticated requests to API Gateway
- Displays job state + insights

**Does NOT:**
- Enforce RBAC as the source of truth (backend must enforce)
- Perform ETL or inference logic

### API Gateway (FastAPI)
**Does:**
- Issues JWT on login
- Validates JWT on protected endpoints
- Enforces RBAC (department isolation)
- Orchestrates dataset upload:
  - write dataset metadata to Postgres
  - upload raw file to S3
  - enqueue ETL job to SQS

**Does NOT:**
- Parse/transform dataset files (ETL does)
- Run ML inference (ML worker does)

### ETL Worker (Event-driven)
**Does:**
- Consumes ETL jobs from SQS
- Downloads raw dataset from S3
- Validates schema (department-specific)
- Transforms/cleans data
- Writes cleaned outputs to Postgres
- Enqueues ML job to SQS after success

**Does NOT:**
- Serve HTTP endpoints
- Perform ML inference

### ML Worker (Event-driven)
**Does:**
- Consumes ML jobs from SQS
- Loads cleaned data from Postgres
- Runs department-specific inference/analytics
- Writes insight results to Postgres

**Does NOT:**
- Serve HTTP endpoints
- Transform raw uploads

---

## 3) Interaction Contracts (What each call “means”)

### Frontend → API Gateway (HTTPS)
- POST /auth/register → creates user + assigns department role
- POST /auth/login → returns JWT
- POST /datasets/upload → triggers upload orchestration
- GET /jobs → returns department-filtered jobs list
- GET /jobs/{job_id} → returns department-filtered job detail
- GET /dashboards/{department} → returns department insights (RBAC enforced)

Security rule: Any mismatch between route department and JWT department must be rejected.

### API Gateway → PostgreSQL (RDS)
Writes/reads:
- Users + roles (department)
- Datasets (metadata: dataset_id, department, uploader_id, created_at)
- Jobs (job_id, dataset_id, stage status)
- Insights (department outputs)

### API Gateway → S3
Writes raw upload file (recommended key structure):
- raw/{department}/{dataset_id}/{original_filename}

### API Gateway → SQS (ETL Queue)
Enqueues ETL job message shape:
{
  "job_type": "etl",
  "dataset_id": "uuid-or-int",
  "department": "sales|supply_chain|finance",
  "s3_bucket": "aetherflow-raw-uploads",
  "s3_key": "raw/sales/<dataset_id>/sales_transactions.csv",
  "requested_by": "user_id",
  "requested_at": "ISO-8601 timestamp"
}

### ETL Worker → SQS (ML Queue)
Enqueues ML job message shape:
{
  "job_type": "ml",
  "dataset_id": "uuid-or-int",
  "department": "sales|supply_chain|finance",
  "requested_by": "etl_worker",
  "requested_at": "ISO-8601 timestamp"
}

---

## 4) What Triggers What (Event Chain)

1) User uploads dataset (Frontend → API)
2) API:
   - stores raw file to S3
   - stores metadata to Postgres
   - enqueues ETL job to SQS
3) ETL worker:
   - validates + transforms
   - writes cleaned data to Postgres
   - enqueues ML job to SQS
4) ML worker:
   - reads cleaned data
   - writes insights to Postgres
5) User views dashboard:
   - Frontend requests insights from API
   - API returns department-specific results (RBAC protected)

---

## 5) Failure + Retry Expectations (MVP)

### ETL Failure
- If schema validation fails:
  - mark job failed in Postgres with reason
  - message retried up to configured attempts
  - after retries, message lands in ETL DLQ

### ML Failure
- If inference fails:
  - mark job failed in Postgres with reason
  - message retried then DLQ’d

Key expectation: every failure must surface a clear reason in the Jobs UI.

---

## 6) Observability Hooks (Minimum Logging)

Every service should log:
- request_id (or correlation_id)
- dataset_id
- job_id (if available)
- department
- status / stage
- duration_ms
