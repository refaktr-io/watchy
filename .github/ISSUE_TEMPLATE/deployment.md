---
name: Deployment Issue
about: Report a deployment or infrastructure problem
title: "[DEPLOY] "
labels: ["deployment", "bug"]
assignees: []
---

## Deployment Issue

### Problem Description
A clear description of what went wrong during deployment.

### GitHub Actions Run
- **Workflow**: Complete CI/CD Pipeline
- **Run URL**: [Link to the failed GitHub Actions run]
- **Environment**: staging/production
- **Triggered by**: push to main/manual/PR

### Error Details
```
[Paste error logs from GitHub Actions here]
```

### Expected Behavior
What should have happened during deployment.

### Steps to Reproduce
1. Go to GitHub Actions
2. Trigger workflow with specific settings
3. See error at specific step

### Environment
- **Repository**: watchy.cloud
- **Branch**: main/develop
- **Commit**: [SHA if known]
- **Deployment target**: s3://watchy.cloud

### AWS Resources Affected
- [ ] CloudFormation stacks
- [ ] S3 buckets
- [ ] Lambda functions
- [ ] CloudFront distributions
- [ ] Other: _______________

### Additional Context
Any additional information about the deployment issue.
