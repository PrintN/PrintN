#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${GITHUB_REPOSITORY_OWNER:-}" ]]; then
  USERNAME="${GITHUB_REPOSITORY_OWNER}"
else
  USERNAME=$(gh api user --jq '.login')
fi

echo "Generating stats for $USERNAME"

TOTAL_STARS=$(gh api "users/$USERNAME/repos?per_page=100" --jq '[.[].stargazers_count] | add // 0')

TOTAL_CONTRIBS=$(gh api graphql -f query='
  query($user: String!) {
    user(login: $user) {
      contributionsCollection {
        contributionCalendar {
          totalContributions
        }
      }
    }
  }' -f user="$USERNAME" --jq '.data.user.contributionsCollection.contributionCalendar.totalContributions')

PRS_CREATED=$(gh api graphql -f query='
  query($user: String!) {
    user(login: $user) {
      pullRequests { totalCount }
    }
  }' -f user="$USERNAME" --jq '.data.user.pullRequests.totalCount')

cat > assets/stats.svg << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg width="500" height="180" xmlns="http://www.w3.org/2000/svg" style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0d1117; border-radius: 12px;">
  <rect width="100%" height="100%" fill="#0d1117" rx="12"/>
  
  <text x="24" y="44" fill="#58a6ff" font-size="28" font-weight="600">${USERNAME}'s GitHub Stats</text>
  
  <text x="24" y="84" fill="#8b949e" font-size="17">Total Stars Earned</text>
  <text x="24" y="114" fill="#ffffff" font-size="32" font-weight="600">${TOTAL_STARS:-0}</text>
  
  <text x="190" y="84" fill="#8b949e" font-size="17">Contributions (past year)</text>
  <text x="190" y="114" fill="#ffffff" font-size="32" font-weight="600">${TOTAL_CONTRIBS:-0}</text>
  
  <text x="380" y="84" fill="#8b949e" font-size="17">Pull Requests</text>
  <text x="380" y="114" fill="#ffffff" font-size="32" font-weight="600">${PRS_CREATED:-0}</text>
  
  <text x="24" y="155" fill="#7c7c7c" font-size="14">Updated $(date -u '+%Y-%m-%d %H:%M UTC')</text>
</svg>
EOF

sed -i '/<!--START_SECTION:stats-->/,/<!--END_SECTION:stats-->/c\<!--START_SECTION:stats-->\n<img src="assets/stats.svg" alt="GitHub Stats"/>\n<!--END_SECTION:stats-->' README.md

echo "stats.svg generated and README updated"