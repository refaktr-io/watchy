# Pull Request

## Description

Brief description of the changes in this PR.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] CloudFormation template update
- [ ] GitHub Actions workflow update

## Changes Made

- [ ] Updated CloudFormation templates
- [ ] Modified Lambda function code (embedded in template)
- [ ] Updated documentation
- [ ] Added/modified GitHub Actions workflows
- [ ] Updated issue templates
- [ ] Other: ___

## Testing

- [ ] CloudFormation template validates successfully
- [ ] Tested deployment in AWS account
- [ ] Verified monitoring functionality works
- [ ] Documentation is accurate and up-to-date
- [ ] GitHub Actions workflow runs successfully

## CloudFormation Testing

If this PR includes CloudFormation changes:

- [ ] Template passes `cfn-lint` validation
- [ ] Template passes AWS CLI validation
- [ ] Successfully deployed to test AWS account
- [ ] Verified all resources are created correctly
- [ ] Tested monitoring functionality
- [ ] Verified cleanup (stack deletion) works

## Deployment Command Used for Testing

```bash
aws cloudformation deploy \
  --template-file templates/watchy-monitoring-slack.yaml \
  --stack-name test-watchy-pr-[PR-NUMBER] \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=test@example.com \
    MonitoringSchedule="rate(5 minutes)"
```

## Screenshots/Logs

If applicable, add screenshots or logs to help explain your changes.

## Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have tested my changes in an AWS environment
- [ ] Any dependent changes have been merged and published

## Additional Notes

Add any additional notes or context about the PR here.