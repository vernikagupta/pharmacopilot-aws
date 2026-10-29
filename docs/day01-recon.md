# Day 1 — AWS sandbox recon

*27–29 Oct 2026*

**Result: everything the project needs is allowed in this sandbox. No changes to the plan.**

## Why Day 1 was recon

The sandbox is a fenced AWS account: some services and actions are blocked, and we didn't know which. Day 1 found the fence before building inside it. Every check answered one question: **can this project run here, and what will it cost?**

## Key ideas

- **Federated user.** Identity lives in the company login system, not in AWS. AWS trusts that sign-in and lets you temporarily take on a **role**. Credentials are short-lived.
- **Role.** A bundle of permissions you "assume". Two were available: a limited self-learning role (no CloudShell) and an admin sandbox role.
- **Least privilege.** Each identity gets only what it needs. Admin is for setup; code (jobs, Lambdas, the agent) will run under narrow **execution roles**.
- **Implicit vs explicit deny.** AWS denies everything by default. "No identity-based policy allows" = nobody granted it (implicit deny). "Explicit deny" = a rule blocks it.
- **Region.** A separate group of AWS data centres. Chosen: **us-east-1**, where new features arrive first and prices are low. Rule: one region for everything.
- **Shared, governed account.** The account belongs to a company **AWS Organization**. Other people's resources exist, activity is logged centrally, and billing is controlled by the **payer account**. Never touch what you didn't create; prefix and tag everything.

## Steps: what, why, result

1. **Picked a region** — us-east-1. Switch allowed.
2. **Opened CloudShell** (a terminal inside AWS). Denied on the limited role (`cloudshell:CreateEnvironment`, implicit deny); worked on the admin role.
3. **Ran identity and access checks.** S3, IAM and CloudFormation all readable. Node v20.20.2, enough for the AgentCore CLI.
4. **Tested internet and the dataset** with curl. figshare reachable; collection 5645578 lists 5 items. Data can go straight from figshare into S3.
5. **Checked Bedrock.** Claude and Nova reply in the playground; Titan Text Embeddings V2 is in the model catalog; AgentCore opens.
6. **Created the S3 bucket** (`pharmacopilot-<account-id>-us-east-1`):
   - Versioning **off** — all data can be rebuilt from scripts; versions make teardown harder.
   - Encryption **SSE-S3** — free, AWS-managed key; enough for public data.
   - Folders `raw/`, `corpus/`, `artifacts/` — S3 has no real folders; these are name prefixes.
   - Tag `project=pharmacopilot` — to find, cost-check and clean up only our resources.
   - Vector buckets (S3 Vectors) visible.
7. **Checked SageMaker quotas.** m5.xlarge: training 30, processing 20, spot 16 · g5.xlarge GPU: 1 · serverless endpoints: 600.
8. **Created a budget** ($300/month). It tracks the whole shared account, not just this project. Filtering by tag was denied: cost allocation tags are controlled by the payer account.
9. **Checked laptop access keys.** The login page is a SAML "Select a role" page with no keys. Work happens in CloudShell and SageMaker Studio.

## Commands and what they mean

Pattern: `aws <service> <action> --<options>`. Full list in [COMMANDS.md](../COMMANDS.md).

| Command | What it answers |
|---|---|
| `aws sts get-caller-identity` | Who am I? Account, role, session |
| `aws configure get region` | Which region am I in? |
| `aws s3 ls` | Can I use S3? |
| `aws iam list-roles --max-items 1` | Can I read IAM? |
| `aws cloudformation list-stacks --max-items 1` | Can I read CloudFormation? |
| `node --version` | Is Node 20+ installed? |

**curl** fetches a web address and prints the raw reply — the way to test the internet without a browser.

- `curl -sI https://figshare.com | head -1` → `HTTP/2 202`. `-s` silent, `-I` headers only (HEAD request), `|` pipes output to the next command, `head -1` keeps the first line. 2xx = success.
- A HEAD request to the figshare API returned `400` (4xx = request was wrong). The API wants a normal GET, so we dropped `-I`.
- The GET returned **JSON**. A small Python one-liner then printed each item's ID and title:

| ID | Item |
|---|---|
| 16676263 | Laboratory.csv |
| 16676320 | Process time series |
| 16676260 | Process.csv |
| 16676266 | Normalization.csv |
| 16780435 | Code availability |

## Sandbox facts

| Item | Value |
|---|---|
| Region | us-east-1 |
| Internet from AWS | Yes |
| Bedrock | Claude, Nova, Titan Text Embeddings V2, AgentCore available |
| S3 Vectors | Available |
| SageMaker quotas | m5.xlarge training 30 / processing 20 / spot 16 · g5.xlarge 1 · serverless endpoints 600 |
| Cost allocation tags | Denied (payer account) |
| Laptop access keys | None — CloudShell and SageMaker Studio |
| CloudShell limits | Only the home folder (~1 GB) is kept; closes after ~20–30 min idle |

## Interview points

- **Federation:** AWS trusts an external identity provider; users assume IAM roles with temporary credentials instead of long-lived IAM users.
- **Debugging access:** start with `aws sts get-caller-identity`, then read the error. Implicit deny = nothing allows it; explicit deny = a rule blocks it.
- **Least privilege:** humans set things up; code runs under narrow execution roles, so a bug or prompt injection can't do more than its role allows.
- **S3 encryption:** SSE-S3 = AWS manages the key. SSE-KMS = you control and audit who can decrypt. DSSE-KMS = two layers, for rules that require it.
- **Versioning:** off in the sandbox because data is reproducible; in GMP production, on, with Object Lock for audit records (data integrity).
- **Tags:** finding, cost tracking, cleanup, and ABAC (tag-based access). With ABAC, tags are security, so lock down who can change them.
- **Organizations:** the payer account controls billing features such as cost allocation tags.
- **Spot vs on-demand; serverless vs real-time:** spot is cheap spare capacity that can be reclaimed; serverless endpoints bill per request, real-time endpoints bill every hour.
