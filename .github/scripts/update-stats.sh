#!/usr/bin/env bash
set -euo pipefail

mkdir -p assets

USERNAME="${GITHUB_REPOSITORY_OWNER:-$(gh api user --jq '.login')}"
YEAR=$(date +%Y)

echo "Generating stats for $USERNAME ($YEAR)"

TOTAL_STARS=$(gh api "users/$USERNAME/repos?per_page=100" --paginate --jq '[.[].stargazers_count] | add // 0')

COMMITS_THIS_YEAR=$(gh api graphql -f query='
query($user: String!, $from: DateTime!) {
  user(login: $user) {
    contributionsCollection(from: $from) {
      contributionCalendar { totalContributions }
    }
  }
}' -f user="$USERNAME" -f from="${YEAR}-01-01T00:00:00Z" --jq '.data.user.contributionsCollection.contributionCalendar.totalContributions')

PRS_CREATED=$(gh api graphql -f query='
query($user: String!) {
  user(login: $user) { pullRequests { totalCount } }
}' -f user="$USERNAME" --jq '.data.user.pullRequests.totalCount')

ISSUES_CREATED=$(gh api graphql -f query='
query($user: String!) {
  user(login: $user) { issues { totalCount } }
}' -f user="$USERNAME" --jq '.data.user.issues.totalCount')

SCORE=$(( TOTAL_STARS * 5 + COMMITS_THIS_YEAR + PRS_CREATED * 3 + ISSUES_CREATED * 2 ))

if   (( SCORE >= 3000 )); then GRADE="S";   PERCENT=100; COLOR="#ff4d4d"
elif (( SCORE >= 2000 )); then GRADE="A++"; PERCENT=$(( SCORE * 100 / 30000 )); COLOR="#ff8000"
elif (( SCORE >= 1500 )); then GRADE="A+";  PERCENT=$(( SCORE * 100 / 20000 )); COLOR="#ffa12c"
elif (( SCORE >= 1000  )); then GRADE="A";   PERCENT=$(( SCORE * 100 / 12000 )); COLOR="#ffd157"
elif (( SCORE >= 750  )); then GRADE="B+";  PERCENT=$(( SCORE * 100 / 8000  )); COLOR="#9ece6a"
elif (( SCORE >= 500  )); then GRADE="B";   PERCENT=$(( SCORE * 100 / 5000  )); COLOR="#7daea3"
else                            GRADE="C";   PERCENT=$(( SCORE * 100 / 3000 )); COLOR="#7daea3"
fi
(( PERCENT > 100 )) && PERCENT=100

CIRCUM=251.2
OFFSET=$(awk "BEGIN {printf \"%.2f\", $CIRCUM - ($CIRCUM * $PERCENT / 100)}")

cat > assets/stats.svg << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="560" height="195" viewBox="0 0 560 195">
  <rect width="560" height="195" rx="14" fill="#0d1117"/>
  
  <g font-family="Segoe UI, system-ui, sans-serif">
    <text x="24"  y="60"  font-size="17" fill="#8b949e">Total Stars Earned</text>
    <text x="24"  y="88" font-size="28" font-weight="600" fill="#ffffff">${TOTAL_STARS:-0}</text>
    
    <text x="24"  y="122" font-size="17" fill="#8b949e">Total Commits ($YEAR)</text>
    <text x="24"  y="150" font-size="28" font-weight="600" fill="#ffffff">${COMMITS_THIS_YEAR:-0}</text>
    
    <text x="280" y="60"  font-size="17" fill="#8b949e">Pull Requests</text>
    <text x="280" y="88" font-size="28" font-weight="600" fill="#ffffff">${PRS_CREATED:-0}</text>
    
    <text x="280" y="122" font-size="17" fill="#8b949e">Issues Opened</text>
    <text x="280" y="150" font-size="28" font-weight="600" fill="#ffffff">${ISSUES_CREATED:-0}</text>
  </g>
  
  <g transform="translate(470,98)" font-family="Segoe UI, system-ui, sans-serif">
    <circle cx="0" cy="0" r="40" fill="none" stroke="#21262d" stroke-width="10"/>
    <circle cx="0" cy="0" r="40" fill="none" stroke="$COLOR" stroke-width="10"
            stroke-dasharray="$CIRCUM" stroke-dashoffset="$OFFSET"
            transform="rotate(-90)" stroke-linecap="round"/>
    <text x="0" y="10" font-size="36" font-weight="700" fill="#ffffff" text-anchor="middle">$GRADE</text>
  </g>
</svg>
EOF

sed -i '' '/<!--START_SECTION:stats-->/,/<!--END_SECTION:stats-->/c\
<!--START_SECTION:stats-->\
<img src="./assets/stats.svg" alt="GitHub Stats"/>\
<!--END_SECTION:stats-->' README.md 2>/dev/null || \
sed -i '/<!--START_SECTION:stats-->/,/<!--END_SECTION:stats-->/c\<!--START_SECTION:stats-->\n<img src="./assets/stats.svg" alt="GitHub Stats"/>\n<!--END_SECTION:stats-->' README.md

echo "Beautiful stats card updated → assets/stats.svg"