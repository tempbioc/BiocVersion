#!/bin/bash

branch="$1"
merge_file="/tmp/merge"
empty_file="/tmp/empty"

rm "$merge_file"
rm "$empty_file"

git log --merges --format="%H %ad %s" --date=format:"%s" > "$merge_file"

git log --format="%H" --reverse --no-merges | tail -n +2 | while read -r commit_hash; do
    if git diff-tree --quiet --ignore-submodules --exit-code -r "$commit_hash"; then
        echo "$commit_hash $(git log --format='%ad %s' --date=format:"%s" -n 1 $commit_hash)" >> "$empty_file"
    fi
done

if [ -s "$merge_file" ] || [ -s "$empty_file" ]; then
  git push origin HEAD:"save_$branch_$(git log -1 --format='%H')"
  while IFS= read -r merge_commit_hash || [[ -n "$merge_commit_hash" ]]; do
    echo $merge_commit_hash
    git rebase --onto "${merge_commit_hash}^" "$merge_commit_hash"
  done < <(cat $merge_file $empty_file | sort -r -k2,2 -n | awk '{print $1}')

 git push origin HEAD:"$branch" --force
fi
