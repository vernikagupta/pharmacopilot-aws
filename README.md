# PharmaCopilot on AWS

An AI system for pharma tablet manufacturing, built on AWS in 30 days.

**Business goal:** catch quality drift while a batch is still being made, and cut the time it takes to investigate a flagged batch — with a human always approving the decision.

## What it does

| Stage | What | AWS services |
|---|---|---|
| 1. Early warning | Predicts drug release (dissolution) from early compression sensor data and raw-material results; flags batches heading toward an alert limit | SageMaker AI (Processing, Training, MLflow, Pipelines, Model Registry, Serverless Inference), Lambda |
| 2. GMP copilot | Answers questions about FDA regulations and guidance, with citations | Bedrock Knowledge Bases on S3 Vectors, Guardrails, Evaluations |
| 3. Investigation agent | Investigates a flagged batch, finds relevant regulations and similar FDA findings, drafts an assessment for human approval | Strands Agents, Bedrock AgentCore, Streamlit |

## Data

- **Batch data:** 1,005 real production batches from a tablet plant (Žagar & Mihelič, *Scientific Data*, 2022). Lab results plus tablet-press sensor data every 10 seconds. [Paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC8943063/) · [Dataset](https://doi.org/10.6084/m9.figshare.c.5645578.v3)
- **GMP corpus:** public FDA documents — 21 CFR Parts 210–211, FDA guidances, warning letters, Form 483 inspection citations.

All batches in the dataset passed spec, so Stage 1 is an early-warning system on drift toward an internal alert limit, not a failure predictor.

## Status

| Phase | Status |
|---|---|
| Phase 0 — sandbox recon | ✅ Done ([notes](docs/day01-recon.md)) |
| Phase 0 — land data | Raw data in S3 ✅; Athena tables next |
| Stage 1 — batch-risk model | Not started |
| Stage 2 — GMP copilot | Not started |
| Stage 3 — investigation agent | Not started |

## Repo layout

```
README.md       project summary and status
COMMANDS.md     command cheat sheet
docs/           daily notes
```

Data files are never committed. Scripts download them from the source.
