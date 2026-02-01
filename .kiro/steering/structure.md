# Project Structure

## Repository Organization

```
watchy-core/
├── cloudformation/                    # Infrastructure as Code
│   ├── watchy-platform.yaml         # Parent stack (shared resources)
│   ├── watchy-monitoring-slack.yaml # Slack monitoring nested stack
│   └── watchy-monitoring-github.yaml # GitHub monitoring nested stack
├── lambda/                           # Serverless functions
│   ├── slack_monitor/               # Slack status monitoring
│   │   └── lambda_function.py       # Main handler (no external deps)
│   ├── github_monitor/              # GitHub incident monitoring
│   │   └── lambda_function.py       # Main handler (no external deps)
│   └── README.md                    # Lambda development guide
├── .github/workflows/               # CI/CD automation
│   └── ci-cd.yaml                   # Build and deployment pipeline
├── .kiro/                           # Kiro IDE configuration
│   └── steering/                    # AI assistant guidance docs
└── README.md                        # Main documentation
```

## Key Directories

### `/cloudformation/`
Contains all CloudFormation templates for infrastructure deployment:
- **Parent Stack**: Manages shared SNS topics, IAM roles, and log groups
- **Nested Stacks**: Individual SaaS monitoring services (Slack, GitHub, future Zoom)
- **Naming Convention**: `watchy-{service}-{type}.yaml` or `watchy-monitoring-{service}.yaml`

### `/lambda/`
Serverless monitoring functions:
- **One directory per service**: Each SaaS service gets its own Lambda function
- **Standard structure**: Each contains `lambda_function.py` with `lambda_handler` entry point
- **No dependencies**: Uses only Python standard library + boto3 for fast cold starts
- **Deployment**: Automatically packaged and uploaded by CI/CD

### `/.github/workflows/`
CI/CD automation:
- **Triggered by**: Changes to `lambda/`, `cloudformation/`, or workflow files
- **Process**: Validates syntax → builds packages → uploads to S3 → deploys templates
- **Security**: Includes automated security scanning

## Architecture Patterns

### Nested Stack Pattern
- **Parent Stack**: Creates shared resources (SNS, IAM, CloudWatch)
- **Child Stacks**: Reference parent resources via parameters
- **Benefits**: Resource sharing, cost optimization, centralized management

### Lambda Function Pattern
- **Handler**: `lambda_function.lambda_handler(event, context)`
- **Environment Variables**: Configuration via CloudFormation
- **Logging**: Structured JSON logs to CloudWatch
- **Metrics**: Published to `Watchy/{ServiceName}` namespace

### Monitoring Pattern
- **API Polling**: Fetch status from public SaaS APIs
- **Metric Publishing**: Convert status to numeric values (0=healthy, 1=notice, 2=incident, 3=outage)
- **Incident Logging**: Smart deduplication based on polling interval
- **Alerting**: CloudWatch alarms trigger SNS notifications

## File Naming Conventions

### CloudFormation Templates
- `watchy-platform.yaml` - Parent stack
- `watchy-monitoring-{service}.yaml` - Service-specific nested stacks

### Lambda Functions
- Directory: `lambda/{service}_monitor/`
- Handler: `lambda_function.py`
- Entry point: `lambda_handler`

### CloudWatch Resources
- Metrics namespace: `Watchy/{ServiceName}` (e.g., `Watchy/Slack`, `Watchy/GitHub`)
- Log groups: `/watchy/{category}/{service}` (e.g., `/watchy/services/slack`, `/watchy/services/github`)
- Alarms: `watchy-{service}-{metric}`
- Dashboards: `watchy-{service}`

## Configuration Management
- **Parameters**: Defined in parent stack, passed to nested stacks
- **Environment Variables**: Set in CloudFormation, consumed by Lambda
- **Defaults**: Sensible defaults for all configurable values
- **Validation**: Parameter constraints and allowed values in templates