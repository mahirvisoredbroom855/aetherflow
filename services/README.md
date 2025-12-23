# /services — Backend Microservices

This directory contains all backend deployable services for AetherFlow.

AetherFlow uses a service boundary approach:
- **API Gateway** handles HTTP, auth verification, RBAC enforcement, and orchestration.
- **ETL Worker** performs transformation and validation of uploaded data.
- **ML Worker** runs department-specific inference and writes insight outputs.

Each service must:
- Be independently runnable and deployable
- Have a single primary responsibility
- Treat cross-service communication as contracts (SQS messages + DB tables)

Services:
- `api_gateway/`
- `etl_worker/`
- `ml_worker/`
