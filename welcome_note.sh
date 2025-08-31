#!/bin/bash

print_line() {
  echo "✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨"
}

print_title() {
  print_line
  echo "🚀🚀🚀🚀🚀   WELCOME TO  RAJA TECH   🚀🚀🚀🚀🚀"
  print_line
  echo ""
}

print_info() {
  echo "🛠️  INFO SECTION:"
  print_line
}

print_footer() {
  echo ""
  print_line
  echo "🏁🏁🏁🏁🏁   END OF INFO   🏁🏁🏁🏁🏁"
  print_line
}

print_title
print_info

# Hostname
echo "🖥️  Hostname: $(hostname)"
echo ""

# Git project info
if [ -d .git ]; then
    branch=$(git rev-parse --abbrev-ref HEAD)
    project=$(basename "$(git rev-parse --show-toplevel)")
    latest_commit_author=$(git log -1 --pretty=format:'%an')
    trigger_user=$(whoami)

    echo "🌿 Branch          : $branch"
    echo "📁 Project Name    : $project"
    echo "🙋 Triggered by    : $trigger_user"
    echo "✍️  Latest Commit By: $latest_commit_author"
else
    echo "⚠️  Warning: Not a git repository."
fi

# GitHub Token Info
if [ -n "$GITHUB_TOKEN" ]; then
    echo ""
    echo "🐙 GitHub Token Info:"
    github_user_resp=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user)

    github_username=$(echo "$github_user_resp" | grep '"login":' | cut -d '"' -f 4)
    echo "👤 Username     : $github_username"

    # Not all tokens will expose created/expires info
    echo "📅 Created At   : N/A"
    echo "⏳ Expires At   : N/A"
else
    echo ""
    echo "⚠️  GitHub token not found in \$GITHUB_TOKEN"
fi

# Docker Token Info
if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PASS" ]; then
    echo ""
    echo "🐳 Docker Hub Token Info:"
    docker_auth_resp=$(curl -s -u "$DOCKER_USER:$DOCKER_PASS" https://hub.docker.com/v2/users/$DOCKER_USER/)
    docker_username=$(echo "$docker_auth_resp" | grep '"username":' | cut -d '"' -f 4)

    if [ -z "$docker_username" ]; then
        echo "⚠️  Could not fetch Docker username. Token may be invalid."
    else
        echo "👤 Username     : $docker_username"
        echo "📅 Created At   : N/A"
        echo "⏳ Expires At   : N/A"
    fi
else
    echo ""
    echo "⚠️  Docker credentials not found in \$DOCKER_USER and \$DOCKER_PASS"
fi

print_footer