#!/usr/bin/env bash
# Weekly dev discovery research — run headless by the claude-discovery systemd
# user timer (Fridays 8:10am). Runs the last30days skill over coding/AI/data-eng/
# software-dev/medical-imaging and writes a summary report for Friday dev
# discovery hour. Read-only: it never modifies repos or config.
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

outdir="$HOME/.claude/dotfiles"
mkdir -p "$outdir"
report="$outdir/discovery-$(date +%F).md"

prompt=$(cat <<'EOF'
You are running Jay's weekly dev discovery research for his Friday morning
"dev discovery hour".

Use the Skill tool to invoke the "last30days" skill with this query:

  top new tools, packages, and trends in coding, AI, data engineering,
  software development, and medical imaging — especially on GitHub and Reddit

Prioritize GitHub (new/trending repos, notable releases) and Reddit
(r/programming, r/MachineLearning, r/dataengineering, r/LocalLLaMA and
similar), with Hacker News as a secondary source. Do NOT query X/Twitter
or YouTube — they are intentionally excluded, so don't mention them as
missing coverage. Skip any other source that needs missing credentials
without stalling.

After the research completes, output a markdown summary (this is your final
message, it is saved to a file):

# Dev Discovery — <date>
## TL;DR
5-8 bullets: the things most worth Jay's attention this week.
## New Tools & Packages
Per item: what it is, why it matters, link, engagement signal (stars/upvotes).
## Trends & Discussions
Notable shifts or debates, grouped by domain (coding / AI / data engineering /
software dev / medical imaging).
## Worth a Deeper Look
2-3 items that merit hands-on time during discovery hour, with a suggested
first step for each.

Do NOT modify any files or repositories — this is a report only.
EOF
)

timeout 20m claude -p "$prompt" \
    --allowedTools "Skill" "Bash" "Read" "Write" "WebSearch" "WebFetch" \
    > "$report" 2>&1 || echo "(discovery run failed or timed out, partial output above)" >> "$report"

echo "Discovery report written to $report"
