# AetherFlow — Department-Aware, Event-Driven Retail Intelligence Platform

![AetherFlow Logo](./docs/brand/AetherFlow%20Logo.png)

AetherFlow is a **department-aware, event-driven data intelligence platform** modeled after a retail/e-commerce organization where different teams (Sales, Supply Chain, Finance) require **isolated data access**, **role-restricted dashboards**, and **asynchronous insight generation** from uploaded datasets.

This repository demonstrates enterprise-grade engineering practices across:
- **Cloud infrastructure design (AWS)**
- **Security architecture (JWT + RBAC + IAM)**
- **Asynchronous job processing (SQS-driven ETL + ML workers)**
- **Infrastructure as Code (Terraform)**
- **CI/CD (GitHub Actions)**
- **Observability (CloudWatch + structured logging + metrics-ready patterns)**
- **Scalable service boundaries (monorepo with deployable services)**

---

## Why AetherFlow Exists (Business Context)

Modern companies generate huge datasets across departments, but the “intelligence stack” is often fragmented:
- Sales dashboards live separately from Supply Chain tooling
- Finance anomaly reviews live in separate spreadsheets
- Data access policies are inconsistent across teams
- Pipelines break silently without monitoring

**AetherFlow** solves this by enforcing an opinionated “enterprise pipeline”:
- **Department role** → restricts upload + read access
- **Uploads** → stored in S3
- **Async pipeline** → ETL worker then ML worker (via SQS)
- **Insights** → persisted in Postgres and visualized in dashboards
- **Monitoring** → job status + logs for traceability

---

## Core User Journey

1. User registers/logs in → receives **JWT** containing a **department role**
2. User uploads a CSV dataset for their department
3. API Gateway stores file to **S3**, metadata to **Postgres**, then enqueues ETL job to **SQS**
4. ETL Worker consumes job → validates + transforms → writes cleaned tables to Postgres → enqueues ML job
5. ML Worker consumes job → runs department-specific inference → writes insights to Postgres
6. Frontend dashboard loads insights via API Gateway using **RBAC** authorization

---

## Tech Stack (MVP)

| Layer | Technology | Notes |
|------|------------|------|
| Frontend | Next.js (TypeScript) | Role-aware dashboard + upload + monitoring |
| API | FastAPI | JWT auth + RBAC middleware + REST endpoints |
| Storage | S3 | Raw uploads + artifacts |
| DB | Postgres (RDS) | Structured truth: users, datasets, jobs, insights |
| Async | SQS | ETL queue + ML queue + DLQs |
| Compute | ECS Fargate | API + workers (separate services) |
| IaC | Terraform | Provision AWS resources consistently |
| CI/CD | GitHub Actions | Lint/test/build workflow hooks |
| Ops | CloudWatch | Logs and operational visibility |

---

## Repository Layout

# AetherFlow — Department-Aware, Event-Driven Retail Intelligence Platform

![AetherFlow Logo](./docs/brand/AetherFlow%20Logo.png)

AetherFlow is a **department-aware, event-driven data intelligence platform** modeled after a retail/e-commerce organization where different teams (Sales, Supply Chain, Finance) require **isolated data access**, **role-restricted dashboards**, and **asynchronous insight generation** from uploaded datasets.

This repository demonstrates enterprise-grade engineering practices across:
- **Cloud infrastructure design (AWS)**
- **Security architecture (JWT + RBAC + IAM)**
- **Asynchronous job processing (SQS-driven ETL + ML workers)**
- **Infrastructure as Code (Terraform)**
- **CI/CD (GitHub Actions)**
- **Observability (CloudWatch + structured logging + metrics-ready patterns)**
- **Scalable service boundaries (monorepo with deployable services)**

---

## Why AetherFlow Exists (Business Context)

Modern companies generate huge datasets across departments, but the “intelligence stack” is often fragmented:
- Sales dashboards live separately from Supply Chain tooling
- Finance anomaly reviews live in separate spreadsheets
- Data access policies are inconsistent across teams
- Pipelines break silently without monitoring

**AetherFlow** solves this by enforcing an opinionated “enterprise pipeline”:
- **Department role** → restricts upload + read access
- **Uploads** → stored in S3
- **Async pipeline** → ETL worker then ML worker (via SQS)
- **Insights** → persisted in Postgres and visualized in dashboards
- **Monitoring** → job status + logs for traceability

---

## Core User Journey

1. User registers/logs in → receives **JWT** containing a **department role**
2. User uploads a CSV dataset for their department
3. API Gateway stores file to **S3**, metadata to **Postgres**, then enqueues ETL job to **SQS**
4. ETL Worker consumes job → validates + transforms → writes cleaned tables to Postgres → enqueues ML job
5. ML Worker consumes job → runs department-specific inference → writes insights to Postgres
6. Frontend dashboard loads insights via API Gateway using **RBAC** authorization

---

## Tech Stack (MVP)

| Layer | Technology | Notes |
|------|------------|------|
| Frontend | Next.js (TypeScript) | Role-aware dashboard + upload + monitoring |
| API | FastAPI | JWT auth + RBAC middleware + REST endpoints |
| Storage | S3 | Raw uploads + artifacts |
| DB | Postgres (RDS) | Structured truth: users, datasets, jobs, insights |
| Async | SQS | ETL queue + ML queue + DLQs |
| Compute | ECS Fargate | API + workers (separate services) |
| IaC | Terraform | Provision AWS resources consistently |
| CI/CD | GitHub Actions | Lint/test/build workflow hooks |
| Ops | CloudWatch | Logs and operational visibility |

---

## Repository Layout

# AetherFlow — Department-Aware, Event-Driven Retail Intelligence Platform

![AetherFlow Logo](./docs/brand/AetherFlow%20Logo.png)

AetherFlow is a **department-aware, event-driven data intelligence platform** modeled after a retail/e-commerce organization where different teams (Sales, Supply Chain, Finance) require **isolated data access**, **role-restricted dashboards**, and **asynchronous insight generation** from uploaded datasets.

This repository demonstrates enterprise-grade engineering practices across:
- **Cloud infrastructure design (AWS)**
- **Security architecture (JWT + RBAC + IAM)**
- **Asynchronous job processing (SQS-driven ETL + ML workers)**
- **Infrastructure as Code (Terraform)**
- **CI/CD (GitHub Actions)**
- **Observability (CloudWatch + structured logging + metrics-ready patterns)**
- **Scalable service boundaries (monorepo with deployable services)**

---

## Why AetherFlow Exists (Business Context)

Modern companies generate huge datasets across departments, but the “intelligence stack” is often fragmented:
- Sales dashboards live separately from Supply Chain tooling
- Finance anomaly reviews live in separate spreadsheets
- Data access policies are inconsistent across teams
- Pipelines break silently without monitoring

**AetherFlow** solves this by enforcing an opinionated “enterprise pipeline”:
- **Department role** → restricts upload + read access
- **Uploads** → stored in S3
- **Async pipeline** → ETL worker then ML worker (via SQS)
- **Insights** → persisted in Postgres and visualized in dashboards
- **Monitoring** → job status + logs for traceability

---

## Core User Journey

1. User registers/logs in → receives **JWT** containing a **department role**
2. User uploads a CSV dataset for their department
3. API Gateway stores file to **S3**, metadata to **Postgres**, then enqueues ETL job to **SQS**
4. ETL Worker consumes job → validates + transforms → writes cleaned tables to Postgres → enqueues ML job
5. ML Worker consumes job → runs department-specific inference → writes insights to Postgres
6. Frontend dashboard loads insights via API Gateway using **RBAC** authorization

---

## Tech Stack (MVP)

| Layer | Technology | Notes |
|------|------------|------|
| Frontend | Next.js (TypeScript) | Role-aware dashboard + upload + monitoring |
| API | FastAPI | JWT auth + RBAC middleware + REST endpoints |
| Storage | S3 | Raw uploads + artifacts |
| DB | Postgres (RDS) | Structured truth: users, datasets, jobs, insights |
| Async | SQS | ETL queue + ML queue + DLQs |
| Compute | ECS Fargate | API + workers (separate services) |
| IaC | Terraform | Provision AWS resources consistently |
| CI/CD | GitHub Actions | Lint/test/build workflow hooks |
| Ops | CloudWatch | Logs and operational visibility |

---

## Repository Layout


- `services/` — backend deployables (API + workers)
- `web/` — frontend apps (Next.js)
- `infra/` — Terraform infrastructure provisioning
- `ops/` — CI/CD and operational configs
- `docs/` — architecture docs and design materials
- `tests/` — integration / end-to-end tests
- `sample_data/` — realistic datasets (with edge cases)

---

## Documentation Map

Start here if you’re reviewing as an interviewer:
- **Service boundaries:** `docs/architecture/service-interactions.md`
- **Data flow:** `docs/architecture/data-flow.md`
- **Tech choices:** `docs/architecture/technology-stack.md`

---

## Status & Badges (activate once workflows exist)

- CI: `TODO`
- Infrastructure deploy: `TODO`
- Lint/Test: `TODO`

---

## How to Run (High-Level)

> Full local run instructions will live in `/docs/runbook/` once Phase 1.2 is completed.

For now, each component is independently runnable:
- API Gateway: `services/api_gateway/`
- ETL Worker: `services/etl_worker/`
- ML Worker: `services/ml_worker/`
- Dashboard: `web/dashboard/`

---

## Security Model (MVP)

- JWT authentication at API Gateway
- RBAC enforced server-side:
  - Sales users can only access Sales datasets/jobs/insights
  - Supply Chain users can only access Supply Chain datasets/jobs/insights
  - Finance users can only access Finance datasets/jobs/insights
- AWS IAM roles for ECS tasks restrict access to:
  - S3 buckets
  - SQS queues
  - CloudWatch logs

---

## License

MIT (portfolio-friendly).

