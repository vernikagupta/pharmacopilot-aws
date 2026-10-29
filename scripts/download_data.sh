#!/usr/bin/env bash
# Download the Zagar & Mihelic tablet-manufacturing dataset from figshare
# straight into S3, then check every file arrived complete.
#
# Usage (in CloudShell):
#   export BUCKET=pharmacopilot-<account-id>-us-east-1
#   bash scripts/download_data.sh
#
# Source: https://doi.org/10.6084/m9.figshare.c.5645578.v3 (CC BY 4.0)

set -euo pipefail   # stop on any error, unset variable, or failed pipe step

# The bucket name comes from an environment variable, never from code,
# so the account ID never lands in this public repo.
BUCKET="${BUCKET:?Set it first: export BUCKET=pharmacopilot-<account-id>-us-east-1}"
PREFIX="raw/zagar-mihelic"

# figshare item IDs in collection 5645578
ARTICLES="16676263 16676320 16676260 16676266 16780435"

MANIFEST="$(mktemp)"
printf "article_id\tfile_name\tsize_bytes\tmd5\ts3_key\n" > "$MANIFEST"

for ID in $ARTICLES; do
  echo "== figshare item $ID"

  # Ask the figshare API which files this item holds.
  # Each output line: file_name <tab> size <tab> md5 <tab> download_url
  FILES="$(curl -sf "https://api.figshare.com/v2/articles/$ID" | python3 -c '
import json, sys
a = json.load(sys.stdin)
for f in a["files"]:
    print(f["name"], f["size"], f.get("computed_md5") or "", f["download_url"], sep="\t")
')"

  while IFS=$'\t' read -r NAME SIZE MD5 URL; do
    SAFE_NAME="${NAME// /_}"                 # spaces -> underscores for clean S3 keys
    KEY="$PREFIX/$ID/$SAFE_NAME"
    echo "   -> $NAME ($SIZE bytes)"

    # Stream: figshare -> pipe -> S3. "-" tells aws s3 cp to read from the pipe.
    curl -sfL "$URL" | aws s3 cp - "s3://$BUCKET/$KEY" --expected-size "$SIZE" --only-show-errors

    # Check: the size in S3 must equal the size figshare reported.
    # This catches half downloads and bot-protection pages saved by mistake.
    REMOTE_SIZE="$(aws s3api head-object --bucket "$BUCKET" --key "$KEY" \
                   --query ContentLength --output text)"
    if [ "$REMOTE_SIZE" = "$SIZE" ]; then
      echo "      OK: size matches"
    else
      echo "      SIZE MISMATCH: figshare $SIZE, S3 $REMOTE_SIZE. Stopping." >&2
      exit 1
    fi

    printf "%s\t%s\t%s\t%s\t%s\n" "$ID" "$NAME" "$SIZE" "$MD5" "$KEY" >> "$MANIFEST"
  done <<< "$FILES"
done

# Save a manifest: what was downloaded, from where, how big, and its checksum.
aws s3 cp "$MANIFEST" "s3://$BUCKET/$PREFIX/manifest.tsv" --only-show-errors
echo
echo "Done. Files in s3://$BUCKET/$PREFIX/:"
aws s3 ls "s3://$BUCKET/$PREFIX/" --recursive --human-readable
