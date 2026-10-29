# Command cheat sheet

Pattern for every AWS CLI command:

```
aws <service> <action> --<options>
```

Get help for any service: `aws <service> help` (for example `aws s3 help`).

## Session setup

```bash
export AWS_PAGER=""          # turn off the scroll viewer (the ":" prompt). If stuck in it, press q
```

## Who and where am I?

```bash
aws sts get-caller-identity  # which account and role am I using? Run this first on any permission error
aws configure get region     # which region am I in?
```

## Access checks

```bash
aws s3 ls                                     # can I use S3? lists all buckets
aws iam list-roles --max-items 1              # can I read IAM roles? (CDK needs IAM)
aws cloudformation list-stacks --max-items 1  # can I read CloudFormation? (CDK deploys through it)
node --version                                # Node 20+ needed for the AgentCore CLI
```

## Internet and the dataset

```bash
# Is the internet reachable? (-s silent, -I headers only, head -1 keeps the status line)
curl -sI https://figshare.com | head -1

# Read the dataset's details from the figshare API (a normal GET; the API rejects -I)
curl -s https://api.figshare.com/v2/collections/5645578 | head -c 400; echo

# List the dataset's items as "ID title"
curl -s https://api.figshare.com/v2/collections/5645578/articles \
  | python3 -c "import json,sys; [print(a['id'], a['title']) for a in json.load(sys.stdin)]"
```

## HTTP status codes

| Code | Meaning |
|---|---|
| 2xx | Success |
| 4xx | Your request was wrong (for example 400 = bad request, 403 = forbidden) |
| 5xx | The server failed |
