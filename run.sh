#!/bin/bash

AVATAR="https://github.com/actions.png"

EMBED_COLOR=15158332
STATUS_MESSAGE="Failed"

AUTHOR_NAME="$(git log -1 "$GITHUB_SHA" --pretty="%aN")"
COMMITTER_NAME="$(git log -1 "$GITHUB_SHA" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "$GITHUB_SHA" --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 "$GITHUB_SHA" --pretty="%b")" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g'
COMMIT_URL="https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
echo "Author"
echo $AUTHOR_NAME
echo "Commit_message"
echo $COMMIT_MESSAGE
echo "COMMITTER _NAME"
echo $COMMITTER_NAME
echo "OCMMIT_URL"
echo $COMMIT_URL
# If, for example, $GITHUB_REF = refs/heads/feature/example-branch
# Then this sed command returns: feature/example-branch
BRANCH_NAME="$(echo $BRANCH)"
REPO_URL="https://github.com/$GITHUB_REPOSITORY"
BRANCH_OR_PR="Branch"
BRANCH_OR_PR_URL="$REPO_URL/tree/$BRANCH_NAME"
ACTION_URL="$COMMIT_URL/checks"
COMMIT_OR_PR_URL=$COMMIT_URL
if [ "$AUTHOR_NAME" == "$COMMITTER_NAME" ]; then
  CREDITS="$AUTHOR_NAME authored & committed"
else
  CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
fi

if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
	BRANCH_OR_PR="Pull Request"

	PR_NUM=$(sed 's/\/.*//g' <<< $BRANCH_NAME)
	BRANCH_OR_PR_URL="$REPO_URL/pull/$PR_NUM"
	BRANCH_NAME="#${PR_NUM}"

	# Call to GitHub API to get PR title
	PULL_REQUEST_ENDPOINT="https://api.github.com/repos/$GITHUB_REPOSITORY/pulls/$PR_NUM"

	WORK_DIR=$(dirname ${BASH_SOURCE[0]})
	PULL_REQUEST_TITLE=$(ruby $WORK_DIR/get_pull_request_title.rb $PULL_REQUEST_ENDPOINT)

	COMMIT_SUBJECT=$PULL_REQUEST_TITLE
	COMMIT_MESSAGE="Pull Request #$PR_NUM"
	ACTION_URL="$BRANCH_OR_PR_URL/checks"
	COMMIT_OR_PR_URL=$BRANCH_OR_PR_URL
fi

TIMESTAMP=$(date -u +%FT%TZ)
WEBHOOK_DATA='{
  "username": "",
  "avatar_url": "'$AVATAR'",
  "embeds": [ {
    "color": '$EMBED_COLOR',
    "author": {
      "name": "'"$STATUS_MESSAGE"': '"$WORKFLOW_NAME"' - '"$GITHUB_REPOSITORY"'",
      "url": "'$ACTION_URL'",
      "icon_url": "'$AVATAR'"
    },
    "title": "'"$COMMIT_SUBJECT"'",
    "url": "'"$COMMIT_OR_PR_URL"'",
    "description": "'"${COMMIT_MESSAGE//$'\n'/ }"\\n\\n"$CREDITS"'",
    "fields": [
      {
        "name": "Commit",
        "value": "'"[\`${GITHUB_SHA:0:7}\`](${COMMIT_URL})"'",
        "inline": true
      },
      {
        "name": "'"$BRANCH_OR_PR"'",
        "value": "'"[\`${BRANCH_NAME}\`](${BRANCH_OR_PR_URL})"'",
        "inline": true
      }
    ],
    "timestamp": "'"$TIMESTAMP"'"
  } ]
}'

for ARG in "$@"; do
  echo -e "[Webhook]: Sending webhook to Discord...\\n";

  (curl --fail --progress-bar -A "GitHub-Actions-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "${WEBHOOK_DATA//	/ }" "$ARG" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
done
