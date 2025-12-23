# AetherFlow ETL Worker

The ETL Worker is an **event-driven processing service** that consumes dataset upload jobs from SQS, transforms raw files, and writes cleaned/validated outputs into Postgres.

It is not an HTTP service.

---

## Single Responsibility

**“Consume dataset jobs → validate schema → transform → write clean results to Postgres → enqueue ML job.”**

---

## Dependencies

- **SQS** — consumes ETL jobs; enqueues ML jobs
- **S3** — downloads raw upload files
- **Postgres** — writes cleaned tables + job state updates

---

## Contract

- Input: SQS message with `{ dataset_id, department, s3_key }`
- Output:
  - Postgres cleaned tables (department-specific)
  - Postgres job status updated
  - New SQS message enqueued for ML job stage

---

## Idempotency (Non-Negotiable)

The ETL worker must be safe to retry:
- If the same dataset_id is processed twice, the resulting tables must not duplicate rows.
- Strategy (common): write to `clean_*` tables using dataset_id as partition key, or use upserts keyed by primary IDs.

---

## Validation Rules (MVP)

- Validate required columns exist by department schema
- Validate basic types (date parsable, numeric fields numeric)
- Reject files that fail validation and mark job as failed with reason

---

## Failure Behavior (MVP)

- Retry behavior is handled by SQS + consumer logic
- After N retries, message should land in DLQ (infrastructure config)
- Worker must write job failure reason in Postgres

---

## Outputs Written (MVP)

- Cleaned dataset table(s) per department
- Job status table update (`queued → processing → succeeded/failed`)
- Audit fields: `processed_at`, row_count, error_count
