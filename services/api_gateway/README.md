# AetherFlow API Gateway (FastAPI)

The API Gateway is the **only HTTP entrypoint** for AetherFlow.

It provides:
- Authentication (issue JWT)
- Authorization (RBAC enforcement)
- Request routing + orchestration (upload → store → enqueue)
- REST API contracts for the dashboard

It does **not** perform:
- ETL/data transformation
- ML inference
- heavy business computations

---

## Single Responsibility

**“Accept authenticated HTTP requests, enforce RBAC, coordinate storage and messaging, and return JSON responses.”**

---

## External Dependencies

- **PostgreSQL** (RDS) — users, datasets, jobs, insights
- **S3** — raw dataset uploads
- **SQS** — enqueue ETL jobs and ML jobs
- *(Optional)* Redis — caching / rate-limiting in future phases

---

## API Contract (MVP)

All endpoints return JSON.
All endpoints except auth require a valid JWT.

### Authentication
- `POST /auth/register` — register user (department role assigned)
- `POST /auth/login` — returns JWT

### Data Upload + Orchestration
- `POST /datasets/upload` — upload CSV, store to S3, write metadata to Postgres, enqueue ETL job to SQS

### Monitoring
- `GET /jobs` — list jobs for the authenticated user’s department
- `GET /jobs/{job_id}` — view job details

### Dashboards
- `GET /dashboards/{department}` — returns department-specific insights (RBAC protected)

### Health
- `GET /health` — basic service health

---

## Security Requirements

- JWT contains:
  - `sub` (user id)
  - `department` (Sales / Supply / Finance)
- RBAC middleware must:
  - block cross-department access at the server
  - filter queries by department scope (`department = token.department`)

---

## Data Ownership Rules

- Users may upload datasets ONLY for their department
- Users may read ONLY:
  - datasets belonging to their department
  - jobs belonging to their department
  - insights belonging to their department

---

## Operational Notes

Logging should be structured and include:
- request_id / correlation_id
- user_id
- department
- endpoint + status_code + latency

This supports debugging across async pipeline stages.
