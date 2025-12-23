# /tests — Integration and End-to-End Tests

This directory contains test suites that validate AetherFlow as a system.

Test categories (planned):
- Integration tests: API Gateway + Postgres
- Queue-driven tests: ETL/ML workers consuming test messages
- E2E tests: user journey from login → upload → job status → dashboard

Testing principles:
- Prefer deterministic tests using sample datasets under `/sample_data`
- Validate RBAC boundaries (cross-department access must fail)
- Validate idempotency (same job twice is safe)
- Validate failure behavior (DLQ routing after retries)
