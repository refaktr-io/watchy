# Watchy Slack Monitor - Latest Version

## Quick Deploy

[![Deploy to AWS](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=watchy-slack-monitor&templateURL=https://templates.watchy.cloud/slack-status/watchy-slack-status-binary.yaml)

## Manual Deployment

```bash
aws cloudformation create-stack \
  --stack-name watchy-slack-monitor \
  --template-body file://watchy-slack-status-binary.yaml \
  --parameters \
    ParameterKey=SlackStatusApiUrl,ParameterValue=https://status.slack.com/api/v2.0.0/current \
    ParameterKey=MonitoringSchedule,ParameterValue="rate(5 minutes)" \
  --capabilities CAPABILITY_NAMED_IAM
```

## Features

- ✅ **Always Latest** - Automatically downloads and runs the newest version
- ✅ **Zero Configuration** - Works out of the box
- ✅ **Protected Source** - Compiled binary hides implementation
- ✅ **Instant Updates** - New releases available immediately