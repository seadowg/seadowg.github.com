# How to Git with Github

*Disclaimer: At the time of writing, [the default Git branch name is still `master`](https://sfconservancy.org/news/2020/jun/23/gitbranchname/) so this post will use `master` instead of `main`. Hopefully I can come back and change that later once `main` (which seems to be gaining traction as the new standard) has become the default.*

I've contributed to and helped maintain a few different open source projects at this point ([ODK Collect](https://github.com/opendatakit/collect), [Postfacto](https://github.com/pivotal/postfacto), [Robolectric](https://github.com/robolectric/robolectric) etc) and something I've noticed is that people run into problems with Git. Crazy right? Git? Confusing? No way!

Git is a "sharp tool". That's software engineer speak for "I already learned this, and now you need to".  Github doesn't do an amazing job of taming it and, although Pull Requests are an important and valuable part of open source work, they can land you in even more treacherous waters.

For this post, I thought I'd just write out a few workflows I use for dealing with situations in ascending order of insanity. This will give me something to reference in the future when I'm helping others (or myself) get out of these situations. I'd advise going deeper on a lot the concepts mentioned here in the [Git Book](https://git-scm.com/book/en/v2) as I could well be wrong about everything. 

Anyway, we're going to start right at the beginning: 

### Starting work on your first PR for a project

**Scenario:**

- We need to create our own remote repo so we don't lose our work if our computer goes on fire
- We want to make sure we're writing code and committing on top of the latest code to make merging easier later

**Steps:**

- Fork the project by hitting the "Fork" button in the top right corner of the project's page
- Clone the fork by copying the URL (either SSH or HTTPS) that we get from the fork's "Clone or download" button and running `git clone <url>`
- **DON'T START YOUR WORK ON MASTER.** Create a new branch off `master` with `git checkout -b <branch-name>`
- Create the branch in your remote repo (fork) with `git push -u origin <branch-name>`

### Creating a PR

**Scenario:**

- We've finished our work and want to contribute it back to the project
- We want to create a Pull Request that the project maintainers can review and merge

**Steps:**

- Make sure your remote branch is up-to-date with `git push <branch-name>`
- Go to the project's page and hit "New Pull Request"
- If there is a link to "compare across forks" click that
- Select your fork as "head repository" and your branch as "compare"
- Make sure to answer any questions that the PR template asks (not doing so is a great way to annoy people)
- Once you've described your changes hit "Create pull request" or if you're note ready for review (you're going to make more changes or want earlier feedback) hit the dropdown on that button and then "Create draft pull request"

### Starting work on a new PR

**Scenario:**

- We've already forked the project and cloned it locally
- We've made PRs to the project before or have one in review already
- We need to make sure our local `master` is up-to-date (with the project's) and start  a new feature branch

**Steps:**

- Add the project as a remote repo in your local repo with `git remote add upstream <project-repo-url>`
- Fetch any updates to the project's repo with `git fetch upstream`
- Update your local master with `git checkout master` and `git merge upstream/master --ff-only`.
- If the above fails it means your master has conflicting changes. In this scenario it's most likely that you've accidentally been committing to on top of `master`
- Create a new feature branch with `git checkout -b <branch-name>`

### Updating a PR when it has conflicts with master

**Scenario:**

- PR has conflicts according to Github and can't be merged
- Need to rebase PR on top of `master`

**Steps:**

- Update `master` (with a `git pull upstream/master`) and then perform a `git rebase master` in PR's branch and solve conflicts as they come up
- Update PR with `git push -f`

OK those are the "basics". The next section is mainly going to deal with "dependent PRs" - when you have one pull request that uses a feature branch that is based off **another feature branch** rather than `master`. You should avoid this at all costs, but sometimes it's necessary when working on dependent changes while earlier ones are reviewed.

### Updating dependent PR  after original merged to master

**Scenario:**

- PR #1 merged
- We need to update dependent PR #2 as it includes commits from PR #2

**Steps:**

- Update `master` (with a `git pull upstream/master`) and then perform a `git rebase master` in PR #2's branch
- Update PR #2 with `git push -f` - you'll see the number of commits reduce

### Updating dependent PR once original changed

**Scenario:**

- PR #2 depends (includes commits from) PR #1
- Commits added on top of PR #1
- We need to rebase PR #2 on top of PR #1 to include new commits

**Steps:**

- Perform a `git rebase <pr-1-branch>` in PR #2's branch
- Update PR with `git push -f`

### Updating dependent PR after original is rebased

**Scenario:**

- PR #1 rebased on top of `master` (or any other branch)
- PR #2 includes commits from PR #1 before rebase (commits have different SHA)
- We need to rebase PR #2 on top of PR #1 but not include the old commits from PR #1 (same changes but with old SHAs)
- To do this we need to rebase onto the PR #1 branch but choose a new "base commit" to rebase from - basically "rebase everything here after this commit onto this branch"

**Steps:**

- Perform `git rebase --onto <pr-1-branch> <commit-sha>~1`
- `commit-sha` is the SHA for the first commit in PR #2

### Updating dependent PR after original merged as a single commit (squashed)

**Scenario:**

- PR #1 squashed onto `master` as a single commit
- PR #2 includes commits from PR #1 before merge that now don't exist on `master`
- We need to rebase PR #2 on top of `master` but not include the old commits from PR #1
- To do this we need to rebase onto the master branch but choose a new "base commit" to rebase from - basically "rebase everything here after this commit onto this branch"

**Steps:**

- Perform `git rebase --onto master <commit-sha>~1`
- `commit-sha` is the SHA for the first commit in PR #2

### Creating a hotfix from a set of specific merged PRs

**Scenario:**

- PR #1, PR #2 and PR #3 have all been merged onto `master` (with merge commits)
- We need to create a hotfix release of our software with PR #1 and PR #3, but don't want to include the changes in PR #2
- To do this, we need to create a new branch and then cherry pick the merge commits for the two PRs we want - effectively squashing the commits of each PR into one commit

**Steps:**

- Create a branch for your current version's hotfixes (if you don't have on already) by checking out the last release with `git checkout <release-tag-or-commit-sha>` and then performing `git checkout -b <hotfix-branch-name>`
- Get the commit SHA for PR #1's merge commit - if it's unclear, you can do `git log --first-parent master` to view `master`'s commit log without the individual commits from each PR (just the merge commits)
- Perform `git cherry-pick -m 1 <pr-1-commit-sha>` - this `cherry-picks` all the changes in the merge commit against its first parent (`master`) giving you a single commit on `<hotfix-branch-name>` with all the changes in PR #1
Repeat the above two steps for PR #3