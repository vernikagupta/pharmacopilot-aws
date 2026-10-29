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

## Linux basics (know by heart)

```bash
ls -lh                 # list files with readable sizes
cd folder / cd ~       # go into a folder / go to home folder
mkdir -p folder        # make a folder (no error if it exists)
head -3 file.csv       # first 3 lines: check columns before using a file
du -sh folder          # total size of a folder
rm -rf folder          # delete a folder and everything in it. NO UNDO
cmd1 | cmd2            # pipe: send cmd1's output into cmd2
cmd | wc -l            # count lines of output
export NAME=value      # set a variable for this terminal session
```

## Git

```bash
git clone https://github.com/vernikagupta/pharmacopilot-aws.git   # copy the repo here
git pull                                                           # get the latest changes
```

## Day 2: land the data

```bash
export BUCKET=pharmacopilot-<account-id>-us-east-1   # never put the account ID in code
bash scripts/download_data.sh                         # figshare -> S3, size-checked, unzipped

aws s3 cp src s3://bucket/path/ --recursive           # upload a whole folder
aws s3 ls s3://bucket/path/ | wc -l                   # count files in an S3 folder
aws s3 ls s3://bucket/path/ --recursive --human-readable   # list with sizes
```

## HTTP status codes

| Code | Meaning |
|---|---|
| 2xx | Success |
| 4xx | Your request was wrong (for example 400 = bad request, 403 = forbidden) |
| 5xx | The server failed |
