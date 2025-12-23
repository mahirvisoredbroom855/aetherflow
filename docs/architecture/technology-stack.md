# Technology Stack — AetherFlow (MVP)

This document defines technology choices per service and justifies each choice.

---

## API Gateway
- Python 3.11+
- FastAPI
- SQLAlchemy (or equivalent ORM) + psycopg2
- boto3 (S3 + SQS integration)
- PyJWT (JWT issuing + verification)

**Justification:** FastAPI provides high-performance REST endpoints and automatic OpenAPI documentation, making the API interface readable and professional.

---

## ETL Worker
- Python 3.11+
- Pandas
- boto3
- psycopg2
- Department schema validation module

**Justification:** Pandas is ideal for MVP-grade transformation while still demonstrating correct service boundaries and pipeline reliability.

---

## ML Worker
- Python 3.11+
- scikit-learn (or simple statistical baseline methods)
- boto3
- psycopg2

**Justification:** AetherFlow prioritizes end-to-end pipeline maturity; lightweight models allow measurable outputs while you demonstrate the enterprise system around them.

---

## Frontend Dashboard
- Next.js 14+
- React 18+
- TypeScript
- Tailwind CSS
- Recharts (charts)

**Justification:** Next.js + TS is modern, production-aligned, and shows frontend engineering maturity.

---

## Infrastructure
- Terraform 1.5+
- AWS ECS Fargate, RDS Postgres, S3, SQS, ALB, CloudWatch, IAM

**Justification:** Terraform + AWS demonstrates real-world infrastructure provisioning and cloud deployment readiness, with a cost-effective container runtime (Fargate).
