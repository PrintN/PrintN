#!/usr/bin/env bash
set -euo pipefail

USERNAME="${GITHUB_REPOSITORY_OWNER:-$(gh api user --jq '.login')}"

TOTAL_STARS=$(gh api "users/$USERNAME/repos?per_page=100" --jq '[.[].stargazers_count] | add // 0')

YEAR=$(date +%Y)

COMMITS_THIS_YEAR=$(gh api graphql -f query='
  query($user: String!, $from: DateTime!) {
    user(login: $user) {
      contributionsCollection(from: $from) {
        contributionCalendar { totalContributions }
      }
    }
  }' -f user="$USERNAME" -f from="${YEAR}-01-01T00:00:00Z" --jq '.data.user.contributionsCollection.contributionCalendar.totalContributions')

PRS_CREATED=$(gh api graphql -f query='
  query($user: String!) { user(login: $user) { pullRequests { totalCount } } }' 
  -f user="$USERNAME" --jq '.data.user.pullRequests.totalCount')

ISSUES_CREATED=$(gh api graphql -f query='
  query($user: String!) { user(login: $user) { issues { totalCount } } }' 
  -f user="$USERNAME" --jq '.data.user.issues.totalCount')

SCORE=$(( TOTAL_STARS * 5 + COMMITS_THIS_YEAR + PRS_CREATED * 3 + ISSUES_CREATED * 2 ))
if   (( SCORE >= 30000 )); then GRADE="S";  PERCENT=100; COLOR="#ff4d4d"
elif (( SCORE >= 20000 )); then GRADE="A++"; PERCENT=$(( SCORE * 100 / 30000 )); COLOR="#ff8000"
elif (( SCORE >= 12000 )); then GRADE="A+";  PERCENT=$(( SCORE * 100 / 20000 )); COLOR="#ffa12c"
elif (( SCORE >= 8000  )); then GRADE="A";   PERCENT=$(( SCORE * 100 / 12000 )); COLOR="#ffd157"
elif (( SCORE >= 5000  )); then GRADE="B+";  PERCENT=$(( SCORE * 100 / 8000  )); COLOR="#9ece6a"
elif (( SCORE >= 3000  )); then GRADE="B";   PERCENT=$(( SCORE * 100 / 5000  )); COLOR="#7daea3"
else GRADE="C"; PERCENT=$(( SCORE * 100 / 3000 )); COLOR="#7daea3"
fi
[[ $PERCENT -gt 100 ]] && PERCENT=100

CIRCUM=251.2
OFFSET=$(awk "BEGIN {print $CIRCUM - ($CIRCUM * $PERCENT / 100)}")

cat > assets/stats.svg << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="560" height="195" viewBox="0 0 560 195">
  <rect width="560" height="195" rx="14" fill="#0d1117"/>
 
  <g font-family="Segoe UI, system-ui, sans-serif">
    <text x="24" y="80"  font-size="17" fill="#8b949e">Total Stars Earned</text>
    <text x="24" y="108" font-size="28" font-weight="600" fill="#ffffff">${TOTAL_STARS:-0}</text>
    
    <text x="24" y="142" font-size="17" fill="#8b949e">Total Commits (${YEAR})</text>
    <text x="24" y="170" font-size="28" font-weight="600" fill="#ffffff">${COMMITS_THIS_YEAR:-0}</text>
    
    <text x="280" y="80"  font-size="17" fill="#8b949e">Pull Requests</text>
    <text x="280" y="108" font-size="28" font-weight="600" fill="#ffffff">${PRS_CREATED:-0}</text>
    
    <text x="280" y="142" font-size="17" fill="#8b949e">Issues Opened</text>
    <text x="280" y="170" font-size="28" font-weight="600" fill="#ffffff">${ISSUES_CREATED:-0}</text>
  </g>
  
  <g transform="translate(470,98)">
    <circle cx="0" cy="0" r="40" fill="none" stroke="#21262d" stroke-width="10"/>
    <circle cx="0" cy="0" r="40" fill="none" stroke="$COLOR" stroke-width="10"
            stroke-dasharray="$CIRCUM" stroke-dashoffset="$OFFSET"
            transform="rotate(-90)" stroke-linecap="round"/>
    <text x="0" y="-12" font-size="36" font-weight="700" fill="#ffffff" text-anchor="middle">$GRADE</text>
    <text x="0" y="20" font-size="16" fill="#8b949e" text-anchor="middle">${PERCENT}%</text>
  </g>
  
  <text x="24" y="190" font-size="13" fill="#7c7c7c">Updated $(date -u '+%Y-%m-%d %H:%M UTC')</text>
</svg>
EOF

sed -i '/<!--START_SECTION:stats-->/,/<!--END_SECTION:stats-->/c\<!--START_SECTION:stats-->\n<img src="assets/stats.svg" alt="GitHub Stats"/>\n<!--END_SECTION:stats-->' README.md

echo "Beautiful stats card generated!"