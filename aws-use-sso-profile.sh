#!/usr/bin/env bash

# Usage: aws-use-sso <profile-name>
#
# Behavior, in order:
#   1. If ~/.aws/sso-creds.sh is still valid for this profile (>5 min headroom),
#      exit silently — no `aws` calls.
#   2. Otherwise try `aws configure export-credentials`, which silently refreshes
#      via the cached SSO access/refresh token (no browser) when possible.
#   3. Only if that fails, fall back to `aws sso login` (browser).
set -euo pipefail

PROFILE="${1:-}"
CREDS_FILE="${HOME}/.aws/sso-creds.sh"

if [[ -z "$PROFILE" ]]; then
    echo "Usage: aws-use-sso <profile-name>"
    exit 1
fi

# Returns 0 if CREDS_FILE holds env-var creds for $PROFILE whose
# AWS_CREDENTIAL_EXPIRATION is >5 min away.
creds_valid() {
    local exp exp_epoch now_epoch
    [[ -f "$CREDS_FILE" ]] || return 1
    # Creds must belong to the requested profile (write_creds tags the file).
    grep -qxF "export AWS_PROFILE=\"$PROFILE\"" "$CREDS_FILE" || return 1
    exp=$(grep -E '^export AWS_CREDENTIAL_EXPIRATION=' "$CREDS_FILE" | head -1 | cut -d= -f2- | tr -d '"')
    [[ -n "$exp" ]] || return 1
    # BSD date (macOS) wants +0000, not +00:00. GNU date accepts ISO-8601 directly.
    exp_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "${exp/+00:00/+0000}" +%s 2>/dev/null \
              || date -d "$exp" +%s 2>/dev/null) || return 1
    now_epoch=$(date +%s)
    (( exp_epoch - now_epoch > 300 ))
}

# Exports creds for $PROFILE to CREDS_FILE atomically (temp file + rename), tagging
# the file with the profile that produced it. A failed export never truncates an
# existing creds file, and concurrent `source` readers never see a partial write.
write_creds() {
    local tmp
    tmp=$(mktemp "${CREDS_FILE}.XXXXXX")
    if aws configure export-credentials --profile "$PROFILE" --format env > "$tmp"; then
        echo "export AWS_PROFILE=\"$PROFILE\"" >> "$tmp"
        mv -f "$tmp" "$CREDS_FILE"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Fast path: existing creds still valid → do nothing.
if creds_valid; then
    echo "✅ Credentials still valid, skipping login."
    echo "Run: source $CREDS_FILE"
    exit 0
fi

# Silent refresh path: cached SSO token (or its refresh_token) is still good.
if write_creds 2>/dev/null; then
    echo "✅ Credentials refreshed silently."
    echo "Run: source $CREDS_FILE"
    exit 0
fi

# Slow path: SSO session genuinely expired — open browser.
echo "🔐 Logging into SSO for profile: $PROFILE..."
aws sso login --profile "$PROFILE"

echo "📦 Exporting credentials to $CREDS_FILE..."
write_creds

echo "✅ Credentials exported to $CREDS_FILE"
echo "Run: source $CREDS_FILE"
