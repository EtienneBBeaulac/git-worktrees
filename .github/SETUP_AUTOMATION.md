# Setup Release Automation - Step by Step

Follow these steps to enable fully automated releases:

## Step 1: Create Personal Access Token (2 minutes)

1. **Open this link:** https://github.com/settings/tokens/new

2. **Fill in the form:**
   - Token name: `TAP_UPDATE_TOKEN`
   - Expiration: `No expiration` (or choose a date)
   - Select scopes:
     - ✅ Check `repo` (Full control of private repositories)
     - ✅ Check `workflow` (Update GitHub Action workflows)

3. **Click "Generate token"** (green button at bottom)

4. **IMPORTANT:** Copy the token that appears (starts with `ghp_...`)
   - You won't be able to see it again!
   - Keep this tab open until you complete Step 2

---

## Step 2: Add Token to Repository Secrets (1 minute)

1. **Open this link:** https://github.com/EtienneBBeaulac/git-worktrees/settings/secrets/actions/new

2. **Fill in the form:**
   - Name: `TAP_UPDATE_TOKEN`
   - Secret: Paste the token you copied from Step 1

3. **Click "Add secret"** (green button)

---

## Step 3: Test It! (30 seconds)

Now test that it works:

```bash
cd ~/git/personal/git-worktrees

# Create a test release
git tag v1.0.2-test
git push origin v1.0.2-test

# Watch the workflow run:
# https://github.com/EtienneBBeaulac/git-worktrees/actions
```

You should see:
- ✅ The workflow runs successfully
- ✅ Formula gets updated in main repo
- ✅ Formula gets updated in homebrew-tap
- ✅ GitHub release is created

If everything looks good, delete the test release:

```bash
# Delete test tag
git tag -d v1.0.2-test
git push origin :refs/tags/v1.0.2-test

# Delete test release from GitHub:
# https://github.com/EtienneBBeaulac/git-worktrees/releases
```

---

## ✅ Done!

From now on, releasing is just:

```bash
git tag v1.0.2
git push origin v1.0.2
```

Everything else happens automatically! 🎉

---

## Troubleshooting

**If the workflow fails:**

1. Check the workflow run logs:
   https://github.com/EtienneBBeaulac/git-worktrees/actions

2. Common issues:
   - Token doesn't have correct scopes → Create new token with `repo` + `workflow`
   - Token is named wrong → Must be exactly `TAP_UPDATE_TOKEN`
   - Token expired → Create new token with no expiration

3. To update the token:
   - Go to: https://github.com/EtienneBBeaulac/git-worktrees/settings/secrets/actions
   - Click on `TAP_UPDATE_TOKEN`
   - Click "Update secret"
   - Paste new token value

