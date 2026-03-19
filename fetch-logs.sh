#!/usr/bin/env bash
# fetch-logs.sh — Pull latest GitHub Actions workflow logs into this folder
#
# Usage:
#   ./fetch-logs.sh            # saves logs to build-logs/latest.txt
#   ./fetch-logs.sh --watch    # streams live until run completes
#
# Requires: gh CLI  (brew install gh  or  https://cli.github.com)
#           gh auth login  (run once to authenticate)

set -euo pipefail

REPO="JoeDotCom/NiceNano-PageTurner"
LOG_DIR="$(dirname "$0")/build-logs"
LOG_FILE="$LOG_DIR/latest.txt"

mkdir -p "$LOG_DIR"

# ── Optional: stream a live run ──────────────────────────────────────────────
if [[ "${1:-}" == "--watch" ]]; then
  echo "Watching latest run (Ctrl-C to stop)..."
  gh run watch --repo "$REPO"
  exit 0
fi

# ── Get the most recent run ──────────────────────────────────────────────────
echo "Fetching latest workflow run..."
RUN_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId --jq '.[0].databaseId')
STATUS=$(gh run list --repo "$REPO" --limit 1 --json status,conclusion --jq '.[0] | "\(.status) / \(.conclusion)"')

echo "Run ID : $RUN_ID"
echo "Status : $STATUS"
echo ""

# ── Download logs ─────────────────────────────────────────────────────────────
echo "Downloading logs → $LOG_FILE"

# --log-failed only prints failing steps (much less noise)
gh run view "$RUN_ID" \
  --repo "$REPO" \
  --log-failed \
  > "$LOG_FILE" 2>&1 || true

# If no failures, grab full log instead
if [[ ! -s "$LOG_FILE" ]]; then
  echo "(No failed steps — writing full log instead)"
  gh run view "$RUN_ID" --repo "$REPO" --log > "$LOG_FILE" 2>&1 || true
fi

echo ""
echo "Done. Logs saved to: $LOG_FILE"
echo "Claude can now read this file from the project folder."
echo ""
echo "── Last 40 lines ──────────────────────────────────────────────"
tail -40 "$LOG_FILE"
