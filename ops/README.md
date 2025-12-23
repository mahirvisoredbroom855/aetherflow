# /ops — Operational Configuration

This folder contains operational and production-readiness artifacts:
- CI/CD workflow definitions (GitHub Actions)
- Deployment scripts (if used)
- Monitoring and logging conventions
- Runbooks (incident / debugging procedures)
- Environment conventions

AetherFlow focuses on “real-world readiness”:
- CI gates (lint/test/build) before merge
- Structured logs with correlation IDs
- Job visibility and failure reporting
- Clear operational ownership and system contracts
