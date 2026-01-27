import json
import os
import sys
import time
import urllib.request
import urllib.parse
import re
import boto3
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List

# Version information - will be set during build
VERSION = os.getenv('LAMBDA_VERSION', '1.0.0')

# Build trigger: Updated 2025-01-26 - Force rebuild for S3 deployment fix

def log_json(level: str, message: str, **kwargs):
    """Log structured JSON messages to reduce visual clutter"""
    if level in ['ERROR', 'WARN', 'INFO']:
        log_data = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'level': level,
            'message': message,
            **kwargs
        }
        print(json.dumps(log_data))

def fetch_slack_status(api_url: str) -> Dict[str, Any]:
    """Fetch Slack status from status API"""
    try:
        log_json("INFO", "Fetching Slack status", api_url=api_url)

        req = urllib.request.Request(api_url)
        req.add_header('User-Agent', f'Watchy-SlackMonitor/{VERSION}')

        with urllib.request.urlopen(req, timeout=30) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                log_json("INFO", "Successfully fetched Slack status")
                return data
            else:
                raise Exception(f"API returned status {response.status}")

    except Exception as e:
        log_json("ERROR", "Failed to fetch Slack status", error=str(e))
        raise

def strip_html_tags(html_string: str) -> str:
    """Remove HTML tags from a string and clean up formatting"""
    if not html_string:
        return ""

    # Remove HTML tags
    clean = re.sub(r'<[^>]+>', '', html_string)

    # Replace common HTML entities
    clean = clean.replace('&nbsp;', ' ')
    clean = clean.replace('&amp;', '&')
    clean = clean.replace('&lt;', '<')
    clean = clean.replace('&gt;', '>')
    clean = clean.replace('&quot;', '"')
    clean = clean.replace('&#39;', "'")

    # Clean up whitespace
    clean = re.sub(r'\s+', ' ', clean.strip())

    return clean

def parse_datetime(date_string: str) -> datetime:
    """Parse Slack API datetime string to datetime object"""
    try:
        # Handle timezone offset
        if date_string.endswith('Z'):
            # UTC timezone
            return datetime.fromisoformat(date_string.replace('Z', '+00:00'))
        elif '+' in date_string[-6:] or '-' in date_string[-6:]:
            # Has timezone offset
            return datetime.fromisoformat(date_string)
        else:
            # Assume UTC if no timezone
            return datetime.fromisoformat(date_string + '+00:00')
    except Exception as e:
        log_json("WARN", "Failed to parse datetime", date_string=date_string, error=str(e))
        return datetime.now(timezone.utc)

def is_within_polling_interval(note_time: datetime, polling_interval_minutes: int = 5) -> bool:
    """Check if a note timestamp is within the last polling interval"""
    # Convert both times to UTC for proper comparison
    now_utc = datetime.now(timezone.utc)
    note_time_utc = note_time.astimezone(timezone.utc)

    cutoff_time = now_utc - timedelta(minutes=polling_interval_minutes)

    # Debug logging to help diagnose time filtering issues
    time_diff_minutes = (now_utc - note_time_utc).total_seconds() / 60
    within_interval = note_time_utc >= cutoff_time

    log_json("DEBUG", "Time interval check",
            note_time_utc=note_time_utc.isoformat(),
            now_utc=now_utc.isoformat(),
            cutoff_time=cutoff_time.isoformat(),
            time_diff_minutes=round(time_diff_minutes, 2),
            polling_interval_minutes=polling_interval_minutes,
            within_interval=within_interval)

    return within_interval

def publish_incident_logs(incidents: List[Dict], log_group: str = '/watchy/slack', polling_interval: int = 5):
    """Publish incident notes to CloudWatch Logs"""
    try:
        if not incidents:
            log_json("INFO", "No active incidents to log")
            return 0

        # Initialize CloudWatch Logs client
        logs_client = boto3.client('logs')

        # Ensure log group exists
        try:
            logs_client.create_log_group(logGroupName=log_group)
            log_json("DEBUG", "Created CloudWatch log group", log_group=log_group)
        except logs_client.exceptions.ResourceAlreadyExistsException:
            pass  # Log group already exists
        except Exception as e:
            log_json("ERROR", "Failed to create log group", log_group=log_group, error=str(e))

        logs_published = 0
        log_events = []

        for incident in incidents:
            incident_id = incident.get('id', 'unknown')
            incident_title = incident.get('title', 'Unknown Incident')
            incident_url = incident.get('url', '')
            incident_type = incident.get('type', 'incident')
            incident_status = incident.get('status', 'unknown')
            incident_services = incident.get('services', [])

            log_json("INFO", "Processing incident",
                    incident_id=incident_id,
                    incident_title=incident_title,
                    incident_type=incident_type,
                    incident_status=incident_status,
                    services=incident_services)

            notes = incident.get('notes', [])
            log_json("DEBUG", "Found incident notes",
                    incident_id=incident_id,
                    notes_count=len(notes))

            for note_idx, note in enumerate(notes):
                note_body = note.get('body', '')
                note_date_str = note.get('date_created', '')

                log_json("DEBUG", "Processing note",
                        incident_id=incident_id,
                        note_index=note_idx,
                        note_date_str=note_date_str,
                        note_body_length=len(note_body) if note_body else 0)

                if not note_body or not note_date_str:
                    log_json("WARN", "Skipping note with missing data",
                            incident_id=incident_id,
                            note_index=note_idx,
                            has_body=bool(note_body),
                            has_date=bool(note_date_str))
                    continue

                # Parse note timestamp
                note_time = parse_datetime(note_date_str)

                # Check if note is within polling interval (smart deduplication)
                within_interval = is_within_polling_interval(note_time, polling_interval)

                if not within_interval:
                    log_json("DEBUG", "Skipping old note (already logged in previous poll)",
                            note_time=note_time.isoformat(),
                            polling_interval_min=polling_interval)
                    continue

                # Clean HTML from note body
                clean_note = strip_html_tags(note_body)

                # Create log entry - use note timestamp as the log timestamp
                log_entry = {
                    'timestamp': note_time.isoformat(),
                    'incident_id': incident_id,
                    'incident_title': incident_title,
                    'incident_type': incident_type,
                    'incident_status': incident_status,
                    'incident_url': incident_url,
                    'affected_services': incident_services,
                    'note_body': clean_note,
                    'source': 'watchy-slack-monitor',
                    'version': VERSION
                }

                # Add to CloudWatch log events
                log_events.append({
                    'timestamp': int(note_time.timestamp() * 1000),  # CloudWatch expects milliseconds
                    'message': json.dumps(log_entry)
                })

                log_json("DEBUG", "Prepared incident log for CloudWatch",
                        incident_id=incident_id,
                        incident_title=incident_title,
                        note_time=note_time.isoformat())

                logs_published += 1

        # Only create log stream and publish if we have events to publish
        if log_events:
            # Sort events by timestamp (CloudWatch requirement)
            log_events.sort(key=lambda x: x['timestamp'])

            # Create log stream with date and timestamp in name
            now = datetime.now(timezone.utc)
            log_stream = f"slack-incidents-{now.strftime('%Y-%m-%d')}-{int(time.time())}"

            try:
                logs_client.create_log_stream(
                    logGroupName=log_group,
                    logStreamName=log_stream
                )
                log_json("DEBUG", "Created CloudWatch log stream",
                        log_group=log_group,
                        log_stream=log_stream)
            except logs_client.exceptions.ResourceAlreadyExistsException:
                pass  # Log stream already exists
            except Exception as e:
                log_json("ERROR", "Failed to create log stream", error=str(e))

            # Publish in batches (CloudWatch limit is 10,000 events or 1MB per call)
            batch_size = 100  # Conservative batch size
            events_published = 0

            for i in range(0, len(log_events), batch_size):
                batch = log_events[i:i + batch_size]

                try:
                    response = logs_client.put_log_events(
                        logGroupName=log_group,
                        logStreamName=log_stream,
                        logEvents=batch
                    )
                    events_published += len(batch)

                    log_json("DEBUG", "Published log events batch to CloudWatch",
                            log_group=log_group,
                            log_stream=log_stream,
                            batch_size=len(batch),
                            next_sequence_token=response.get('nextSequenceToken'))

                except Exception as e:
                    log_json("ERROR", "Failed to publish log events batch",
                            log_group=log_group,
                            log_stream=log_stream,
                            batch_size=len(batch),
                            error=str(e))
                    # Continue with next batch

            log_json("INFO", "Successfully published incident logs to CloudWatch",
                    log_group=log_group,
                    log_stream=log_stream,
                    events_published=events_published,
                    incidents_processed=len(incidents))
        else:
            log_json("INFO", "No new incident notes to publish (all notes older than polling interval)")

        return logs_published

    except Exception as e:
        log_json("ERROR", "Failed to publish incident logs",
                error=str(e),
                log_group=log_group,
                incidents_count=len(incidents))
        return 0

def parse_slack_services(status_data: Dict[str, Any]) -> Dict[str, int]:
    """Parse Slack service statuses and convert to numeric values for CloudWatch"""
    try:
        # Define all 11 Slack services
        all_services = [
            "Login/SSO",
            "Messaging",
            "Notifications",
            "Search",
            "Workspace/Org Administration",
            "Canvases",
            "Connectivity",
            "Files",
            "Huddles",
            "Apps/Integrations/APIs",
            "Workflows"
        ]

        # Type mapping: notice=1, incident=2, outage=3
        type_map = {
            'notice': 1,
            'incident': 2,
            'outage': 3
        }

        metrics = {}

        # Initialize all services to 0 (healthy)
        for service in all_services:
            # Convert service name to CloudWatch-friendly metric name
            # Remove slashes, underscores, and spaces to match alarm names
            metric_name = service.replace('/', '').replace(' ', '').replace('_', '')
            metrics[metric_name] = 0

        # Get active incidents
        active_incidents = status_data.get('active_incidents', [])

        # Process each active incident
        for incident in active_incidents:
            incident_type = incident.get('type', 'incident')
            incident_status = incident.get('status', 'active')
            affected_services = incident.get('services', [])

            # Only process active incidents
            if incident_status == 'active':
                severity = type_map.get(incident_type, 2)  # Default to incident (2)

                # Update metrics for affected services
                for service in affected_services:
                    if service in all_services:
                        metric_name = service.replace('/', '').replace(' ', '').replace('_', '')
                        # Use the highest severity if multiple incidents affect same service
                        metrics[metric_name] = max(metrics.get(metric_name, 0), severity)
                        print(f"{service}: {incident_type} (severity: {severity})")

        # Count active incidents
        metrics['ActiveIncidents'] = len(active_incidents)
        print(f"Active Incidents: {len(active_incidents)}")

        # Add overall API response metric
        metrics['APIResponse'] = 200 if status_data else 500

        return metrics

    except Exception as e:
        print(f"Failed to parse Slack services: {e}")
        return {'APIResponse': 500}

def publish_cloudwatch_metrics(metrics: Dict[str, int], namespace: str = 'Watchy/Slack'):
    """Publish metrics to CloudWatch"""
    try:
        # Initialize CloudWatch client
        cloudwatch = boto3.client('cloudwatch')

        # Prepare metric data for batch publishing
        metric_data = []

        for metric_name, value in metrics.items():
            metric_data.append({
                'MetricName': metric_name,
                'Value': value,
                'Unit': 'Count',
                'Timestamp': datetime.now(timezone.utc)
            })

        # Publish metrics in batches (CloudWatch limit is 20 metrics per call)
        batch_size = 20
        metrics_published = 0

        for i in range(0, len(metric_data), batch_size):
            batch = metric_data[i:i + batch_size]

            cloudwatch.put_metric_data(
                Namespace=namespace,
                MetricData=batch
            )

            metrics_published += len(batch)
            log_json("DEBUG", f"Published batch of {len(batch)} metrics to CloudWatch",
                    namespace=namespace, batch_size=len(batch))

        log_json("INFO", "Successfully published metrics to CloudWatch",
                namespace=namespace,
                metrics_count=metrics_published)

        return True

    except Exception as e:
        log_json("ERROR", "Failed to publish CloudWatch metrics",
                error=str(e),
                namespace=namespace,
                metrics_count=len(metrics))
        return False

def lambda_handler(event, context):
    """Main Lambda handler for Slack status monitoring"""
    start_time = time.time()

    try:
        print(f"Watchy Slack Monitor v{VERSION} starting...")
        print("Runtime: Pure Python Lambda")

        # Get configuration from environment variables with defaults
        api_url = os.getenv('API_URL', 'https://status.slack.com/api/v2.0.0/current')
        namespace = os.getenv('CLOUDWATCH_NAMESPACE', 'Watchy/Slack')
        log_group = os.getenv('CLOUDWATCH_LOG_GROUP', '/watchy/slack')
        polling_interval = int(os.getenv('POLLING_INTERVAL_MINUTES', '5'))

        # Debug mode: disable time filtering if DEBUG_DISABLE_TIME_FILTER is set
        disable_time_filter = os.getenv('DEBUG_DISABLE_TIME_FILTER', 'false').lower() == 'true'
        if disable_time_filter:
            print("DEBUG: Time filtering disabled - will log ALL incident notes")
            polling_interval = 60 * 24 * 7  # 1 week - effectively disable filtering

        print(f"Config: Namespace={namespace}, Log Group={log_group}, Polling Interval={polling_interval}min")

        # Fetch Slack status
        status_data = fetch_slack_status(api_url)

        # Parse active incidents and publish logs
        active_incidents = status_data.get('active_incidents', [])

        print(f"DEBUG: Found {len(active_incidents)} active incidents")
        for i, incident in enumerate(active_incidents):
            incident_id = incident.get('id', 'unknown')
            incident_title = incident.get('title', 'Unknown')
            notes_count = len(incident.get('notes', []))
            print(f"  Incident {i+1}: ID={incident_id}, Title='{incident_title}', Notes={notes_count}")

            # Show note timestamps for debugging
            for j, note in enumerate(incident.get('notes', [])):
                note_date = note.get('date_created', 'unknown')
                print(f"    Note {j+1}: {note_date}")

        logs_published = publish_incident_logs(active_incidents, log_group, polling_interval)

        # Parse service statuses
        metrics = parse_slack_services(status_data)

        # Publish to CloudWatch
        publish_cloudwatch_metrics(metrics, namespace)

        # Determine if any services are down (exclude APIResponse and ActiveIncidents)
        service_incidents = sum(1 for key, value in metrics.items()
                               if key not in ['APIResponse', 'ActiveIncidents'] and value >= 2)

        # Execution summary
        execution_time = time.time() - start_time

        print(f"Monitoring completed in {execution_time:.2f}s")
        print(f"Published {len(metrics)} metrics")
        print(f"Published {logs_published} incident logs")
        print(f"Active incidents: {len(active_incidents)}")
        print(f"Service incidents: {service_incidents}")
        print(f"API Response: {metrics.get('APIResponse', 'unknown')}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Slack monitoring completed successfully',
                'saas_app': 'Slack',
                'version': VERSION,
                'execution_time': execution_time,
                'metrics_published': len(metrics),
                'logs_published': logs_published,
                'active_incidents': len(active_incidents),
                'service_incidents': service_incidents,
                'api_response': metrics.get('APIResponse', 'unknown'),
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }

    except Exception as e:
        execution_time = time.time() - start_time
        error_msg = f"Slack monitoring failed: {str(e)}"
        print(f"{error_msg}")

        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg,
                'saas_app': 'Slack',
                'version': VERSION,
                'execution_time': execution_time,
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }