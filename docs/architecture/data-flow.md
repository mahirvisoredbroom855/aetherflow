# Data Flow — Upload to Dashboard (AetherFlow)

This document defines the “happy path” and failure path for the core pipeline.

---

## Happy Path (Upload → ETL → ML → Dashboard)

1. User logs in via Dashboard → receives JWT from API Gateway
2. User uploads CSV via Dashboard → API Gateway verifies JWT + RBAC
3. API Gateway writes dataset metadata to Postgres:
   - dataset_id, department, uploader_id, created_at, status=queued
4. API Gateway uploads raw file to S3:
   - stores under department prefix + dataset_id
5. API Gateway enqueues ETL job to SQS:
   - includes dataset_id, department, s3_key
6. ETL Worker consumes ETL job:
   - marks job=processing
   - downloads file from S3
   - validates schema (department-specific)
   - transforms + cleans
   - writes cleaned tables to Postgres
   - marks ETL stage = succeeded
7. ETL Worker enqueues ML job to SQS:
   - includes dataset_id, department
8. ML Worker consumes ML job:
   - marks ML stage = processing
   - loads cleaned data from Postgres
   - runs department inference (Sales/Supply/Finance)
   - writes insights to Postgres
   - marks ML stage = succeeded
9. User opens dashboard:
   - Frontend calls API Gateway `/dashboards/{department}`
   - API Gateway enforces RBAC, reads insights from Postgres, returns JSON
10. Frontend renders charts + tables, shows last_updated timestamp.

---

## Failure Scenario (ETL fails)

- If ETL fails validation:
  - ETL Worker marks job failed with reason in Postgres
  - Message may be retried depending on SQS retry strategy
- After N retries:
  - message lands in DLQ
  - job remains failed
  - user sees failure reason on Jobs page
