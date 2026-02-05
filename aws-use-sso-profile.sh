#!/usr/bin/env bash

# Usage: aws-use-sso <profile-name>
set -euo pipefail

PROFILE="${1:-}"
CREDS_FILE="${HOME}/.aws/sso-creds.sh"

if [[ -z "$PROFILE" ]]; then
    echo "Usage: aws-use-sso <profile-name>"
    exit 1
fi

echo "🔐 Logging into SSO for profile: $PROFILE..."
aws sso login --profile "$PROFILE"

echo "📦 Exporting credentials to $CREDS_FILE..."
aws configure export-credentials --profile "$PROFILE" --format env >"$CREDS_FILE"

echo "✅ Credentials exported to $CREDS_FILE"
echo "Run: source $CREDS_FILE"
