#!/usr/bin/env bash
# risk-score.sh — the risk arithmetic from phases/risk.md, so it is never done by
# hand.
#
#   risk-score.sh B R K T G D          human line, for RISK.md
#   risk-score.sh --json B R K T G D   JSON, for scripts
#
# Impact = B×R · Chance = (K+T+G)/3 · Escape = D · Score = Impact×Chance×Escape
# Level: Low ≤ 6 · Mid 7–20 · High > 20. Phase 3 model: High → opus, else sonnet.

set -uo pipefail
JSON=0
[ "${1:-}" = "--json" ] && { JSON=1; shift; }
[ $# -eq 6 ] || { echo "usage: risk-score.sh [--json] B R K T G D   (each 1-3)" >&2; exit 2; }
for v in "$@"; do
  case "$v" in 1|2|3) ;; *) echo "risk-score.sh: every score must be 1, 2 or 3 (got '$v')" >&2; exit 2 ;; esac
done

awk -v B="$1" -v R="$2" -v K="$3" -v T="$4" -v G="$5" -v D="$6" -v json="$JSON" 'BEGIN {
  impact = B * R; chance = (K + T + G) / 3; score = impact * chance * D
  # Band edges compared as whole numbers (score × 3) so 6 and 20 are exact.
  s3 = impact * (K + T + G) * D
  level = s3 <= 18 ? "LOW" : (s3 <= 60 ? "MID" : "HIGH")
  model = level == "HIGH" ? "opus" : "sonnet"
  if (json)
    printf "{\"B\":%d,\"R\":%d,\"K\":%d,\"T\":%d,\"G\":%d,\"D\":%d,\"score\":%.2f,\"level\":\"%s\",\"reviewModel\":\"%s\"}\n", B, R, K, T, G, D, score, level, model
  else
    printf "Score: %g — %s   (Impact %d × Chance %.2f × Escape %d)\nPhase 3 model: %s\n", int(score * 100 + 0.5) / 100, level, impact, chance, D, model
}'
