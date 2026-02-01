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

# Build trigger: Created 2026-02-01 - GitHub monitoring

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

def fetch_github_incidents(api_url: str) -> Dict[str, Any]:
    """Fetch GitHub unresolved incidents from status API"""
    try:
        log_json("INFO", "Fetching GitHub unresolved incidents", api_url=api_url)

        req = urllib.request.Request(api_url)
        req.add_header('User-Agent', f'Watchy-GitHubMonitor/{VERSION}')

        with urllib.request.urlopen(req, timeout=30) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                log_json("INFO", "Successfully fetched GitHub incidents")
                return data
            else:
                raise Exception(f"API returned status {response.status}")

    except Exception as e:
        log_json("ERROR", "Failed to fetch GitHub incidents", error=str(e))
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
    """Parse GitHub API datetime string to datetime object"""
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

def is_within_polling_interval(update_time: datetime, polling_interval_minutes: int = 5) -> bool:
    """Check if an incident update timestamp is within the last polling interval"""
    # Convert both times to UTC for proper comparison
    now_utc = datetime.now(timezone.utc)
    update_time_utc = update_time.astimezone(timezone.utc)

    cutoff_time = now_utc - timedelta(minutes=polling_interval_minutes)

    # Debug logging to help diagnose time filtering issues
    time_diff_minutes = (now_utc - update_time_utc).total_seconds() / 60
    within_interval = update_time_utc >= cutoff_time

    log_json("DEBUG", "Time interval check",
            update_time_utc=update_time_utc.isoformat(),
            now_utc=now_utc.isoformat(),
            cutoff_time=cutoff_time.isoformat(),
            time_diff_minutes=round(time_diff_minutes, 2),
            polling_interval_minutes=polling_interval_minutes,
            within_interval=within_interval)

    return within_interval

def publish_incident_logs(incidents: List[Dict], log_group: str = '/watchy/services/github', polling_interval: int = 5):
    """Publish incident updates to CloudWatch Logs"""
    try:
        if not incidents:
            log_json("INFO", "No unresolved incidents to log")
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
            incident_name = incident.get('name', 'Unknown Incident')
            incident_status = incident.get('status', 'unknown')
            incident_impact = incident.get('impact', 'unknown')
            incident_shortlink = incident.get('shortlink', '')
            incident_created_at = incident.get('created_at', '')
            incident_updated_at = incident.get('updated_at', '')

            log_json("INFO", "Processing GitHub incident",
                    incident_id=incident_id,
                    incident_name=incident_name,
                    incident_status=incident_status,
                    incident_impact=incident_impact)

            # Get affected components
            affected_components = []
            for component in incident.get('components', []):
                affected_components.append(component.get('name', 'Unknown'))

            # Process incident updates
            incident_updates = incident.get('incident_updates', [])
            log_json("DEBUG", "Found incident updates",
                    incident_id=incident_id,
                    updates_count=len(incident_updates))

            for update_idx, update in enumerate(incident_updates):
                update_body = update.get('body', '')
                update_status = update.get('status', '')
                update_created_at = update.get('created_at', '')

                log_json("DEBUG", "Processing incident update",
                        incident_id=incident_id,
                        update_index=update_idx,
                        update_created_at=update_created_at,
                        update_body_length=len(update_body) if update_body else 0)

                if not update_body or not update_created_at:
                    log_json("WARN", "Skipping update with missing data",
                            incident_id=incident_id,
                            update_index=update_idx,
                            has_body=bool(update_body),
                            has_created_at=bool(update_created_at))
                    continue

                # Parse update timestamp
                update_time = parse_datetime(update_created_at)

                # Check if update is within polling interval (smart deduplication)
                within_interval = is_within_polling_interval(update_time, polling_interval)

                if not within_interval:
                    log_json("DEBUG", "Skipping old update (already logged in previous poll)",
                            update_time=update_time.isoformat(),
                            polling_interval_min=polling_interval)
                    continue

                # Clean HTML from update body
                clean_update = strip_html_tags(update_body)

                # Create log entry - use update timestamp as the log timestamp
                log_entry = {
                    'timestamp': update_time.isoformat(),
                    'incident_id': incident_id,
                    'incident_name': incident_name,
                    'incident_status': incident_status,
                    'incident_impact': incident_impact,
                    'incident_shortlink': incident_shortlink,
                    'incident_created_at': incident_created_at,
                    'incident_updated_at': incident_updated_at,
                    'affected_components': affected_components,
                    'update_status': update_status,
                    'update_body': clean_update,
                    'source': 'watchy-github-monitor',
                    'version': VERSION
                }

                # Add to CloudWatch log events
                log_events.append({
                    'timestamp': int(update_time.timestamp() * 1000),  # CloudWatch expects milliseconds
                    'message': json.dumps(log_entry)
                })

                log_json("DEBUG", "Prepared incident log for CloudWatch",
                        incident_id=incident_id,
                        incident_name=incident_name,
                        update_time=update_time.isoformat())

                logs_published += 1

        # Only create log stream and publish if we have events to publish
        if log_events:
            # Sort events by timestamp (CloudWatch requirement)
            log_events.sort(key=lambda x: x['timestamp'])

            # Create log stream with date and timestamp in name
            now = datetime.now(timezone.utc)
            log_stream = f"github-incidents-{now.strftime('%Y-%m-%d')}-{int(time.time())}"

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
            log_json("INFO", "No new incident updates to publish (all updates older than polling interval)")

        return logs_published

    except Exception as e:
        log_json("ERROR", "Failed to publish incident logs",
                error=str(e),
                log_group=log_group,
                incidents_count=len(incidents))
        return 0

def parse_github_incidents(incidents_data: Dict[str, Any]) -> Dict[str, int]:
    """Parse GitHub incidents and convert to numeric values for CloudWatch"""
    try:
        # Impact mapping: none=0, minor=1, major=2, critical=3
        impact_map = {
            'none': 0,
            'minor': 1,
            'major': 2,
            'critical': 3
        }

        metrics = {}
        incidents = incidents_data.get('incidents', [])

        # Count incidents by impact level
        impact_counts = {'none': 0, 'minor': 0, 'major': 0, 'critical': 0}
        
        # Track highest impact level
        max_impact_level = 0
        
        for incident in incidents:
            incident_impact = incident.get('impact', 'none').lower()
            incident_status = incident.get('status', 'unknown').lower()
            incident_name = incident.get('name', 'Unknown')
            
            # Only count unresolved incidents (investigating, identified, monitoring)
            if incident_status in ['investigating', 'identified', 'monitoring']:
                if incident_impact in impact_counts:
                    impact_counts[incident_impact] += 1
                    
                    # Track highest impact level
                    impact_level = impact_map.get(incident_impact, 0)
                    max_impact_level = max(max_impact_level, impact_level)
                    
                    log_json("INFO", "Processing unresolved incident",
                            incident_name=incident_name,
                            incident_impact=incident_impact,
                            incident_status=incident_status,
                            impact_level=impact_level)

        # Set metrics for each impact level
        metrics['IncidentsNone'] = impact_counts['none']
        metrics['IncidentsMinor'] = impact_counts['minor']
        metrics['IncidentsMajor'] = impact_counts['major']
        metrics['IncidentsCritical'] = impact_counts['critical']
        
        # Total unresolved incidents
        total_incidents = sum(impact_counts.values())
        metrics['TotalUnresolvedIncidents'] = total_incidents
        
        # Highest impact level (for alerting)
        metrics['HighestImpactLevel'] = max_impact_level
        
        # Add overall API response metric
        metrics['APIResponse'] = 200 if incidents_data else 500

        log_json("INFO", "GitHub incidents summary",
                total_incidents=total_incidents,
                impact_counts=impact_counts,
                highest_impact_level=max_impact_level)

        return metrics

    except Exception as e:
        log_json("ERROR", "Failed to parse GitHub incidents", error=str(e))
        return {'APIResponse': 500}

def publish_cloudwatch_metrics(metrics: Dict[str, int], namespace: str = 'Watchy/GitHub'):
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
    """Main Lambda handler for GitHub incident monitoring"""
    start_time = time.time()

    try:
        print(f"Watchy GitHub Monitor v{VERSION} starting...")
        print("Runtime: Python Lambda")

        # Get configuration from environment variables with defaults
        api_url = os.getenv('API_URL', 'https://www.githubstatus.com/api/v2/incidents/unresolved.json')
        namespace = os.getenv('CLOUDWATCH_NAMESPACE', 'Watchy/GitHub')
        log_group = os.getenv('CLOUDWATCH_LOG_GROUP', '/watchy/services/github')
        polling_interval = int(os.getenv('POLLING_INTERVAL_MINUTES', '5'))

        # Debug mode: disable time filtering if DEBUG_DISABLE_TIME_FILTER is set
        disable_time_filter = os.getenv('DEBUG_DISABLE_TIME_FILTER', 'false').lower() == 'true'
        if disable_time_filter:
            print("DEBUG: Time filtering disabled - will log ALL incident updates")
            polling_interval = 60 * 24 * 7  # 1 week - effectively disable filtering

        print(f"Config: Namespace={namespace}, Log Group={log_group}, Polling Interval={polling_interval}min")

        # Fetch GitHub incidents
        incidents_data = fetch_github_incidents(api_url)

        # Parse unresolved incidents and publish logs
        unresolved_incidents = incidents_data.get('incidents', [])

        print(f"DEBUG: Found {len(unresolved_incidents)} unresolved incidents")
        for i, incident in enumerate(unresolved_incidents):
            incident_id = incident.get('id', 'unknown')
            incident_name = incident.get('name', 'Unknown')
            incident_impact = incident.get('impact', 'unknown')
            incident_status = incident.get('status', 'unknown')
            updates_count = len(incident.get('incident_updates', []))
            print(f"  Incident {i+1}: ID={incident_id}, Name='{incident_name}', Impact={incident_impact}, Status={incident_status}, Updates={updates_count}")

            # Show update timestamps for debugging
            for j, update in enumerate(incident.get('incident_updates', [])):
                update_created_at = update.get('created_at', 'unknown')
                update_status = update.get('status', 'unknown')
                print(f"    Update {j+1}: {update_created_at} ({update_status})")

        logs_published = publish_incident_logs(unresolved_incidents, log_group, polling_interval)

        # Parse incident metrics
        metrics = parse_github_incidents(incidents_data)

        # Publish to CloudWatch
        publish_cloudwatch_metrics(metrics, namespace)

        # Determine if there are any major/critical incidents
        major_critical_incidents = metrics.get('IncidentsMajor', 0) + metrics.get('IncidentsCritical', 0)

        # Execution summary
        execution_time = time.time() - start_time

        print(f"Monitoring completed in {execution_time:.2f}s")
        print(f"Published {len(metrics)} metrics")
        print(f"Published {logs_published} incident logs")
        print(f"Unresolved incidents: {len(unresolved_incidents)}")
        print(f"Major/Critical incidents: {major_critical_incidents}")
        print(f"Highest impact level: {metrics.get('HighestImpactLevel', 0)}")
        print(f"API Response: {metrics.get('APIResponse', 'unknown')}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'GitHub monitoring completed successfully',
                'saas_app': 'GitHub',
                'version': VERSION,
                'execution_time': execution_time,
                'metrics_published': len(metrics),
                'logs_published': logs_published,
                'unresolved_incidents': len(unresolved_incidents),
                'major_critical_incidents': major_critical_incidents,
                'highest_impact_level': metrics.get('HighestImpactLevel', 0),
                'api_response': metrics.get('APIResponse', 'unknown'),
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }

    except Exception as e:
        execution_time = time.time() - start_time
        error_msg = f"GitHub monitoring failed: {str(e)}"
        print(f"{error_msg}")

        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg,
                'saas_app': 'GitHub',
                'version': VERSION,
                'execution_time': execution_time,
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }