# Product Overview

Watchy is an open-source SaaS monitoring platform that runs in your AWS account to monitor the health of external SaaS services like Slack, GitHub, and Zoom.

## Core Purpose
- Monitor SaaS application status using public status APIs
- Provide real-time alerts for service degradation and incidents
- Track service health metrics in CloudWatch dashboards
- Log incident details for historical analysis

## Key Features
- **Nested Stack Architecture**: Parent stack manages shared resources (SNS, IAM, logs) while nested stacks handle individual SaaS monitoring
- **Cost Effective**: Typical monthly cost of $7-9 USD for complete platform with ARM64 Lambda architecture
- **Transparent**: All monitoring logic visible in CloudFormation templates
- **No External Dependencies**: Uses only AWS services and public APIs
- **Smart Deduplication**: Avoids duplicate incident notifications

## Current Monitoring Support
- **Slack**: Monitors 11 services (Messaging, Login/SSO, Search, Files, etc.)
- **GitHub**: Monitors unresolved incidents by impact level (none, minor, major, critical)
- **Planned**: Zoom and custom SaaS integrations

## Target Users
- DevOps teams needing visibility into SaaS dependencies
- Organizations wanting to monitor critical third-party services
- Teams requiring incident tracking and alerting for external services