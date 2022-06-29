---
layout: post
title: "Managing hot fixes with Git"
---

1. Create a hotfix branch if there isn't one already - `git checkout <last release>`, `git checkout -b <hotfix name>`
2. Switch to the hotfix branch
3. Cherry pick PRs you want from their merge commits - `git cherry-pick -m 1 <merge commit>`

`cherry-pick` does not work on with merge commits as a merge commit has two parents: the branch you're merging from and the branch your merging into. If you're using Pull Requests and merging "feature" branches into your default branch, then the default branch is your first parent and the feature branch is your second parent. 

Using `-m` with `cherry-pick` allows you to tell it what parent to use when working out the changes to apply. We use `-m 1` as we want to apply the changes based on the first parent - our default branch. You can also think of this set of changes as the Pull Request itself - it's the difference between the commit before and then merge commit for the Pull Request itself.

It's important to realize two things when taking this approach to create hot fixes:

1. The changes will be merged as a single commit. If the original PR was multiple commits, that history will be lost
2. The changes are being merged onto a different branch (and therefore snapshot of the code) than the original PR, so you'll need to verify that the goal of the PR is still being satisfied. An older version of your code base might need a different set of changes to fix a bug, for example.