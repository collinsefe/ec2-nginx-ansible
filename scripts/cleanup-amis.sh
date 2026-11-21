#!/bin/bash
set -euo pipefail

AMI_NAME_PREFIX="${1:-team}"
KEEP_COUNT="${2:-5}"
REGION="${3:-eu-west-2}"

echo "🧹 Cleaning up old AMIs"
echo "========================"
echo "Prefix: $AMI_NAME_PREFIX (matches any AMI with this word in name)"
echo "Keep count: $KEEP_COUNT"
echo "Region: $REGION"
echo ""

# Get all AMIs owned by current account, filter for names containing the prefix, sorted by creation date (newest first)
AMIS=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners self \
  --query 'sort_by(Images, &CreationDate) | reverse(@) | [*].[ImageId, Name, CreationDate]' \
  --output json | \
  jq "map(select(.[1] | contains(\"${AMI_NAME_PREFIX}\")))")

TOTAL_AMIS=$(echo "$AMIS" | jq 'length')
echo "Found $TOTAL_AMIS AMIs containing '$AMI_NAME_PREFIX' in name"
echo ""

if [ "$TOTAL_AMIS" -le "$KEEP_COUNT" ]; then
  echo "✓ Only $TOTAL_AMIS AMIs found (keeping all)"
  exit 0
fi

TO_DELETE=$((TOTAL_AMIS - KEEP_COUNT))
echo "Deleting $TO_DELETE old AMI(s), keeping $KEEP_COUNT newest..."
echo ""

# Delete old AMIs (skip first KEEP_COUNT entries which are the newest)
echo "$AMIS" | jq -r ".[$KEEP_COUNT:][] | @tsv" | while read -r ami_id ami_name creation_date; do
  echo "Deleting: $ami_id ($ami_name) created $creation_date"

  # Deregister the AMI
  aws ec2 deregister-image \
    --region "$REGION" \
    --image-id "$ami_id" \
    --output text > /dev/null

  # Delete associated snapshots
  SNAPSHOTS=$(aws ec2 describe-snapshots \
    --region "$REGION" \
    --owner-ids self \
    --filters "Name=description,Values=*$ami_id*" \
    --query 'Snapshots[*].SnapshotId' \
    --output text)

  if [ ! -z "$SNAPSHOTS" ]; then
    for snapshot_id in $SNAPSHOTS; do
      echo "  Deleting snapshot: $snapshot_id"
      aws ec2 delete-snapshot \
        --region "$REGION" \
        --snapshot-id "$snapshot_id" \
        --output text > /dev/null
    done
  fi
done

echo ""
echo "✅ Cleanup complete!"
