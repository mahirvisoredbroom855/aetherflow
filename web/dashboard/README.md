# AetherFlow Dashboard (Next.js)

The dashboard is the user-facing web application for AetherFlow.

It provides:
- Login + registration UI
- Dataset upload experience
- Job monitoring UI
- Department-specific dashboards and visualizations

It does **not** enforce business rules. RBAC is enforced by the API Gateway.

---

## Single Responsibility

**“Render a clean UI that calls the API Gateway and displays results.”**

---

## Dependencies

- **API Gateway** — all functionality is accessed via authenticated REST calls
- JWT is stored client-side (implementation choice: cookie or local storage; MVP can start simple)

---

## Pages (MVP)

- `/login`
- `/register`
- `/upload`
- `/jobs`
- `/dashboard` (role-aware; renders correct department view)

---

## Role-Based Rendering

The frontend renders UI based on the role in JWT:
- Sales users see Sales dashboard components
- Supply Chain users see inventory dashboard components
- Finance users see finance anomaly components

**Important:** The backend must still enforce RBAC for every request.

---

## UI Principles

- “Status visibility first”: jobs page is not optional
- Every dashboard must show:
  - last updated timestamp
  - dataset id reference (for traceability)
  - clear error messages if insights not available yet
