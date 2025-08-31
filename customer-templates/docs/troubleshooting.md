# Troubleshooting Guide

## Common Issues

### Deployment Failures

**Issue**: CloudFormation stack creation fails
**Solution**: 
- Check AWS permissions
- Verify parameter values
- Review CloudFormation events tab

**Issue**: Lambda function timeouts
**Solution**:
- Increase timeout value in template
- Check API endpoint availability
- Review CloudWatch logs

### Monitoring Issues

**Issue**: No alerts being triggered
**Solution**:
- Verify SNS topic configuration
- Check monitoring schedule
- Test API endpoint manually

**Issue**: False positive alerts
**Solution**:
- Adjust alert thresholds
- Review API response format
- Check monitoring logic

## Log Analysis

### CloudWatch Logs
```bash
# View recent logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/watchy"

# Get log events
aws logs get-log-events \
  --log-group-name "/aws/lambda/watchy-slack-monitor" \
  --log-stream-name "$(aws logs describe-log-streams \
    --log-group-name "/aws/lambda/watchy-slack-monitor" \
    --order-by LastEventTime --descending \
    --max-items 1 --query 'logStreams[0].logStreamName' --output text)"
```

## Getting Help

1. Check CloudWatch logs for error details
2. Review CloudFormation events
3. Verify API endpoints are accessible
4. Test with minimal configuration first
