# GitHub Actions Fix: publish-to-github Job

## Problem

The `publish-to-github` job was being skipped when pushing changes to the repository.

## Root Cause

The job had two issues:

### 1. Path Filter Configuration

The `detect-changes` job was not detecting changes to the files we want to publish:

**Before:**
```yaml
platform:
  - 'customer-templates/**'
  - 'platform/deploy/**'
```

**Issue:** Changes to `platform/watchy-platform.yaml`, `platform/README.md`, or `docs/**` were NOT triggering the `platform` output to be `true`.

### 2. Job Dependencies

The job depended on `deploy-platform`, which would cause it to be skipped if the deploy job didn't run:

**Before:**
```yaml
needs: [detect-changes, deploy-platform]
```

**Issue:** If only documentation changed (not requiring deployment), `deploy-platform` might not run, blocking the publish job.

## Solution

### Fix 1: Updated Path Filters

Added the public-facing files to the `platform` filter:

```yaml
platform:
  - 'customer-templates/**'
  - 'platform/deploy/**'
  - 'platform/watchy-platform.yaml'    # ✅ CloudFormation template
  - 'platform/README.md'                # ✅ Public README
  - 'docs/**'                           # ✅ Architecture docs
```

### Fix 2: Removed deploy-platform Dependency

Changed from:
```yaml
needs: [detect-changes, deploy-platform]
```

To:
```yaml
needs: [detect-changes]
```

Now the job only depends on `detect-changes`, allowing it to run independently even if deployment isn't needed.

### Fix 3: Added Architecture Diagram

Added a new step to copy the architecture diagram:

```yaml
- name: Copy Architecture Diagram
  run: |
    echo "📐 Copying architecture diagram to public repository..."
    mkdir -p public-repo/docs
    cp website/watchy-architecture.png public-repo/docs/watchy-architecture.png
    echo "✅ Architecture diagram copied"
```

Updated the git add command to include the docs directory:
```bash
git add watchy-platform.yaml README.md docs/
```

## Files Now Published to refaktr-io/watchy

When changes are pushed to `main` branch, these files are automatically published:

1. **`watchy-platform.yaml`** - CloudFormation template
2. **`README.md`** - Public documentation (from platform/README.md)
3. **`docs/watchy-architecture.png`** - Architecture diagram

## Job Trigger Conditions

The `publish-to-github` job now runs when:

1. ✅ Push to `main` branch
2. ✅ Changes detected in:
   - `platform/watchy-platform.yaml`
   - `platform/README.md`
   - `docs/**` (any file in docs directory)
   - `customer-templates/**`
   - `platform/deploy/**`
3. ✅ OR manual workflow dispatch (workflow_dispatch event)

## Testing

To test the fix:

### Option 1: Make a change to trigger the workflow

```bash
# Edit any of the published files
echo "" >> platform/README.md

# Commit and push to main
git add platform/README.md
git commit -m "Test: Trigger GitHub publishing workflow"
git push origin main
```

### Option 2: Manual trigger

1. Go to: https://github.com/cloudbennett/watchy.cloud/actions
2. Select "Optimized Watchy Platform CI/CD"
3. Click "Run workflow"
4. Select branch: `main`
5. Set `force_infrastructure`: `false` (doesn't matter for publish job)
6. Click "Run workflow"

### Verify Success

1. Check workflow run status: https://github.com/cloudbennett/watchy.cloud/actions
2. Look for "Publish to Public GitHub Repository" job (should show ✅)
3. Verify files published: https://github.com/refaktr-io/watchy
4. Check commit history shows automated commit from `refaktr-automation`

## What Changed in .github/workflows/ci-cd.yaml

```diff
detect-changes:
  steps:
    - uses: dorny/paths-filter@v2
      with:
        filters: |
          infrastructure:
            - 'platform/infrastructure/**'
-           - 'platform/watchy-platform.yaml'
          binaries:
            - 'platform/binaries/**'
          platform:
            - 'customer-templates/**'
            - 'platform/deploy/**'
+           - 'platform/watchy-platform.yaml'
+           - 'platform/README.md'
+           - 'docs/**'
          website:
            - 'website/**'

publish-to-github:
  name: Publish to Public GitHub Repository
  runs-on: ubuntu-latest
- needs: [detect-changes, deploy-platform]
+ needs: [detect-changes]
  if: github.ref == 'refs/heads/main' && (needs.detect-changes.outputs.platform == 'true' || github.event_name == 'workflow_dispatch')
  
  steps:
    # ... existing steps ...
    
    - name: Copy README
      run: |
        echo "📄 Copying README to public repository..."
        cp platform/README.md public-repo/README.md
        echo "✅ README copied"
    
+   - name: Copy Architecture Diagram
+     run: |
+       echo "📐 Copying architecture diagram to public repository..."
+       mkdir -p public-repo/docs
+       cp website/watchy-architecture.png public-repo/docs/watchy-architecture.png
+       echo "✅ Architecture diagram copied"
    
    - name: Commit and push to public repository
      run: |
        cd public-repo
        git config user.name "refaktr-automation"
        git config user.email "automation@refaktr.io"
        
        # Stage changes
-       git add watchy-platform.yaml README.md
+       git add watchy-platform.yaml README.md docs/
        
        # ... rest of commit logic ...
```

## Summary

The `publish-to-github` job will now:

✅ Trigger when platform files (CFT, README, docs) change  
✅ Run independently without waiting for deployment  
✅ Publish CloudFormation template to public repo  
✅ Publish README to public repo  
✅ Publish architecture diagram to public repo  
✅ Create automated commits with version info  
✅ Push to refaktr-io/watchy main branch  

The job should no longer be skipped! 🎉
