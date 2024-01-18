#!/bin/bash

branch="$1"
merge_file="/tmp/merge"
empty_file="/tmp/empty"

git log --merges --format="%H %s" > "$merge_file"

git log --format="%H %s" --reverse --all | while read -r commit_hash; do
  git log --oneline --exit-code --reverse "$commit_hash..$commit_hash~1" && echo "$commit_hash" >> "$empty_file"
done

if [ -s "$merge_file" ] || [ -s "$empty_file" ]; then
  git push origin HEAD:"save_$branch_$(git log -1 --format='%H')"
  while IFS= read -r merge_commit_hash || [[ -n "$line" ]]; do
    git rebase --onto "$merge_commit_hash^" "$merge_commit_hash"
  done < <(cat merge_file empty_file | awk '{print $1}')

  git push origin HEAD:"$branch" --force
fi
