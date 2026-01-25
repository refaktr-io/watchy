# Troubleshooting Guide

## Common Issues

### Deployment Failures

**Issue**: CloudFormation stack creation fails
**Solutions**: 
- Check AWS permissions (need CAPABILITY_NAMED_IAM)
- Verify parameter values (especially NotificationEmail format)
- Review CloudFormation events tab for specific error messages
- Ensure S3 template URLs are accessible

**Issue**: Nested stack deployment fails
**Solutions**:
- Check parent stack has successfully created shared resources
- Verify nested stack template URL is accessible
- Review nested stack events in CloudFormation console
- Ensure IAM permissions allow nested stack creation

**Issue**: Lambda function timeouts
**Solutions**:
- Increase TimeoutSeconds parameter (default: 240)
- Check Slack Status API endpoint availability
- Review CloudWatch logs for specific timeout causes
- Verify Lambda has internet access (check VPC/NAT configuration if applicable)

### Monitoring Issues

**Issue**: No alerts being triggered during known Slack incidents
**Solutions**:
- Verify SNS email subscription is confirmed (check email for confirmation)
- Check CloudWatch alarms are in ALARM state (not just INSUFFICIENT_DATA)
- Test Slack Status API manually: `curl https://status.slack.com/api/v2.0.0/current`
- Review monitoring schedule frequency
- Check Lambda execution logs for errors

**Issue**: False positive alerts
**Solutions**:
- Review CloudWatch alarm thresholds (currently set to alert on severity >= 2)
- Check if API response format has changed
- Verify incident deduplication logic is working (check polling interval)
- Review Lambda logs for parsing errors

**Issue**: Missing CloudWatch metrics
**Solutions**:
- Check Lambda execution logs for metric publishing errors
- Verify IAM role has cloudwatch:PutMetricData permission
- Confirm metrics namespace is correct (Watchy/Slack)
- Test Lambda function manually via AWS console

## Log Analysis

### CloudWatch Log Groups
The nested stack architecture creates several log groups:

```bash
# Platform logs
/watchy/platform/{StackName}

# Slack incident logs (with smart deduplication)
/watchy/slack

# Lambda execution logs
/aws/lambda/{ParentStackName}-SlackMonitor
```

### Viewing Logs
```bash
# List all Watchy-related log groups
aws logs describe-log-groups --log-group-name-prefix "/watchy"

# Get recent Lambda execution logs
aws logs get-log-events \
  --log-group-name "/aws/lambda/Watchy-Platform-SlackMonitor" \
  --log-stream-name "$(aws logs describe-log-streams \
    --log-group-name "/aws/lambda/Watchy-Platform-SlackMonitor" \
    --order-by LastEventTime --descending \
    --max-items 1 --query 'logStreams[0].logStreamName' --output text)"

# Get incident logs
aws logs describe-log-streams \
  --log-group-name "/watchy/slack" \
  --order-by LastEventTime --descending
```

### Log Analysis Tips
- **Structured JSON logs**: All logs use JSON format for easy parsing
- **Smart deduplication**: Incident logs only show new notes within polling interval
- **Error tracking**: All errors include context and stack traces
- **Performance metrics**: Execution time and API response times logged

## Stack Management

### Updating Stacks
```bash
# Update parent stack (will update nested stacks automatically)
aws cloudformation deploy \
  --template-url https://s3.amazonaws.com/watchy-resources-prod/templates/watchy-platform.yaml \
  --stack-name Watchy-Platform \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    NotificationEmail=your-email@domain.com \
    MonitoringSchedule="rate(10 minutes)"
```

### Deleting Stacks
```bash
# Delete parent stack (will delete nested stacks automatically)
aws cloudformation delete-stack --stack-name Watchy-Platform
```

## Testing and Validation

### Manual Testing
```bash
# Test Slack Status API directly
curl -s https://status.slack.com/api/v2.0.0/current | jq '.'

# Invoke Lambda function manually
aws lambda invoke \
  --function-name Watchy-Platform-SlackMonitor \
  --payload '{}' \
  response.json && cat response.json
```

### Validation Checklist
- [ ] SNS email subscription confirmed
- [ ] CloudWatch alarms created for all 11 Slack services
- [ ] Lambda function executing on schedule
- [ ] Metrics appearing in CloudWatch (Watchy/Slack namespace)
- [ ] Incident logs being created during Slack incidents
- [ ] CloudWatch dashboard showing service status

## Getting Help

1. **Check CloudWatch logs** for detailed error messages and execution traces
2. **Review CloudFormation events** for deployment issues
3. **Verify API endpoints** are accessible from your AWS region
4. **Test with minimal configuration** first, then add complexity
5. **Use CloudWatch Insights** to query logs across multiple log groups
6. **Monitor CloudWatch metrics** to ensure data is being collected

## Debug Mode

Enable debug mode by setting environment variable:
```bash
DEBUG_DISABLE_TIME_FILTER=true
```

This will log ALL incident notes (not just recent ones) for troubleshooting deduplication issues.
