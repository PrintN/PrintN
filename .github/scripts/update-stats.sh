#!/usr/bin/env bash
set -e

USERNAME="${GITHUB_REPOSITORY_OWNER:-$(gh api user --jq '.login')}"

TOTAL_STARS=$(gh api -X GET /users/$USERNAME/repos --jq 'map(select(.fork == false)) | map(.stargazers_count) | add')
TOTAL_COMMITS=$(gh api graphql -f query='
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
      pullRequests(first: 100) { totalCount }
    }
  }' -f user="$USERNAME" --jq '.data.user.pullRequests.totalCount')

LANGUAGES=$(gh api /users/$USERNAME/repos --jq 'map(select(.fork|not)) | sort_by(-.size) | .[:5] | map("\(.language)//\(.stargazers_count)") | join(" ")')

cat > stats.svg << EOF
<svg width="500" height="180" xmlns="http://www.w3.org/2000/svg" style="font-family: 'Segoe UI', sans-serif;">
  <rect width="100%" height="100%" fill="#0d1117" rx="12"/>
  
  <text x="20" y="40" fill="#58a6ff" font-size="28" font-weight="600">$USERNAME's Stats</text>
  
  <text x="20" y="80" fill="#8b949e" font-size="16">⭐ Total Stars</text>
  <text x="20" y="105" fill="#ffffff" font-size="24" font-weight="600">$TOTAL_STARS</text>
  
  <text x="170" y="80" fill="#8b949e" font-size="16">📦 Commits (2025)</text>
  <text x="170" y="105" fill="#ffffff" font-size="24" font-weight="600">$TOTAL_COMMITS</text>
  
  <text x="340" y="80" fill="#8b949e" font-size="16">🔃 Pull Requests</text>
  <text x="340" y="105" fill="#ffffff" font-size="24" font-weight="600">$PRS_CREATED</text>

  <text x="20" y="150" fill="#8b949e" font-size="14">Updated: $(date -u '+%Y-%m-%d %H:%M UTC')</text>
</svg>
EOF

sed -i '/<!--START_SECTION:stats-->/,/<!--END_SECTION:stats-->/c\<!--START_SECTION:stats-->\n![](./stats.svg)\n<!--END_SECTION:stats-->' README.md

echo "Stats updated!"