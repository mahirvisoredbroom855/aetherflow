# AetherFlow ML Worker

The ML Worker is an **event-driven inference service** that consumes ML jobs from SQS, loads processed data from Postgres, runs department-specific analytics/inference, and writes insights back to Postgres for dashboards.

It is not an HTTP service.

---

## Single Responsibility

**“Consume ML jobs → compute department insight output → persist insights → mark job complete.”**

---

## Dependencies

- **SQS** — consumes ML jobs
- **Postgres** — reads processed data; writes insights/results
- *(Optional)* S3 — store serialized models/artifacts in future phases

---

## Contract

- Input: SQS message with `{ dataset_id, department }`
- Output:
  - Sales: next-week revenue forecast by category + top-5 categories
  - Supply Chain: stockout risk within 14 days + reorder quantity suggestions
  - Finance: anomaly detection by category + ranked anomaly table with reasons

---

## Model Complexity (MVP)

The MVP prioritizes **verifiable outputs** over heavy ML complexity:
- Sales forecast can start as baseline time-series + aggregation logic
- Inventory logic can be rule-based/projection-based (still “analytics grade”)
- Finance anomalies can start as z-score / IQR-based flagging with explicit reasons

This is intentional: the goal is a full pipeline that’s production-like.

---

## Failure Behavior

- On model error: mark job failed with reason
- Handle missing processed data gracefully (e.g., ETL not done)
- Never crash-loop without writing failure reason

---

## Output Storage Requirements

- Every insight row must contain:
  - dataset_id
  - department
  - computed_at timestamp
  - explanation fields (e.g., “reason”, “severity”, “method”)

This makes dashboards and audits trustworthy.
