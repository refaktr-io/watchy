# Watchy Lambda Functions

This directory contains the Lambda functions that power the Watchy monitoring platform.

## Structure

```
lambda/
├── slack_monitor/
│   └── lambda_function.py        # Slack status monitoring function
└── README.md                     # This file
```

## Functions

### slack_monitor

Monitors Slack service status and publishes metrics to CloudWatch.

**What it does:**
- Fetches status from the Slack Status API every 5 minutes
- Tracks health of 11 Slack services (Messaging, Login/SSO, Search, etc.)
- Publishes metrics to CloudWatch for alerting and dashboards
- Logs incident details for historical tracking
- Automatically deduplicates incident notes

**Metrics published:**
- Service health status: 0=healthy, 1=notice, 2=incident, 3=outage
- Active incident count
- API response status

**Implementation:**
- Python using only standard library + boto3
- No external dependencies
- Optimized for fast cold starts and low memory usage

## Deployment

Lambda functions are automatically built and deployed by the CI/CD pipeline when code changes are detected.

The deployment process:
1. Packages the Python code into a zip file
2. Uploads to S3 (`watchy-resources` bucket)
3. CloudFormation templates reference the S3 package
4. Lambda functions are updated automatically