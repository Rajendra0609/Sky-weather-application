#!/bin/bash

# Decorative function for periodic symbols
print_line() {
  echo "************************************************************"
}

print_title() {
  print_line
  echo "***********************  RAJA TECH  ************************"
  print_line
  echo ""
}

print_info() {
  echo "INFO:"
  print_line
}

print_footer() {
  echo ""
  print_line
  echo "***********************  END OF INFO  **********************"
  print_line
}

print_title
print_info

# Hostname
echo "Hostname: $(hostname)"
echo ""

# Git project info
if [ -d .git ]; then
    branch=$(git rev-parse --abbrev-ref HEAD)
    project=$(basename "$(git rev-parse --show-toplevel)")
    latest_commit_author=$(git log -1 --pretty=format:'%an')
    trigger_user=$(whoami)

    echo "Branch          : $branch"
    echo "Project Name    : $project"
    echo "Triggered by    : $trigger_user"
    echo "Latest Commit By: $latest_commit_author"
else
    echo "Warning: Not a git repository."
fi

print_footer
