# /web — Frontend Applications

This directory contains frontend applications for AetherFlow.

The MVP includes a single app:
- `dashboard/` — Next.js web UI for authentication, upload, monitoring, and role-restricted dashboards.

Frontend principles:
- Stateless UI: stores only JWT token client-side
- All business rules enforced by API Gateway (RBAC is NOT “frontend-only”)
- Strict separation: frontend renders, backend governs access and integrity
