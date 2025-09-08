#!/usr/bin/env python3
"""
Watchy Slack Status Monitor - Nuitka Native Binary Implementation
Complete monitoring solution for Slack status tracking
"""

import json
import os
import sys
import time
import urllib.request
import urllib.parse
import re
import boto3
from datetime import datetime, timedelta
from typing import Dict, Any, List

# Version information
VERSION = "1.0.1-nuitka"
BUILD_DATE = "2025-08-31T10:30:00Z"

def log_json(level: str, message: str, **kwargs):
    """Log structured JSON messages to reduce visual clutter"""
    log_entry = {
        'timestamp': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
        'level': level,
        'message': message
    }
    # Add any additional metadata
    log_entry.update(kwargs)
    print(json.dumps(log_entry))

# Binary cache for intelligent caching
_binary_cache = {}

def get_nuitka_binary_info():
    """Get Slack Nuitka binary information"""
    try:
        base_url = os.environ.get('WATCHY_BINARY_DISTRIBUTION_URL', 'https://releases.watchy.cloud')
        info_url = f"{base_url}/binaries/slack-monitor/metadata.json"
        
        req = urllib.request.Request(info_url)
        req.add_header('User-Agent', f'Watchy-SlackMonitor/{VERSION}')
        
        with urllib.request.urlopen(req, timeout=10) as response:
            if response.status == 200:
                return json.loads(response.read().decode('utf-8'))
        return None
    except Exception as e:
        log_json("ERROR", "Failed to get Slack binary info", error=str(e))
        return None

def ensure_nuitka_binary():
    """Ensure we have the latest Nuitka binary with intelligent caching"""
    try:
        binary_path = "/tmp/watchy-slack-monitor"
        cache_info_path = "/tmp/watchy-slack-cache.json"
        
        # Get latest binary information
        latest_info = get_nuitka_binary_info()
        if not latest_info:
            raise Exception("Failed to get binary information")
        
        # Check if we have cached binary info
        cached_info = None
        if os.path.exists(cache_info_path):
            try:
                with open(cache_info_path, 'r') as f:
                    cached_info = json.loads(f.read())
            except Exception:
                cached_info = None
        
        # Check if binary exists and versions match
        if (cached_info and 
            os.path.exists(binary_path) and 
            cached_info.get('version') == latest_info['version'] and
            cached_info.get('sha256') == latest_info['sha256']):
            
            log_json("INFO", "Using cached Slack binary", 
                    version=latest_info['version'], 
                    size_bytes=cached_info.get('binarySize', 'unknown'))
            return binary_path, latest_info['version']
        
        # For standalone binary, we ARE the binary, so no download needed
        # This is just for consistency with Lambda implementation
        log_json("INFO", "Running Slack binary", version=latest_info.get('version', VERSION))
        
        # Cache the binary info for consistency
        try:
            with open(cache_info_path, 'w') as f:
                json.dump({
                    'version': latest_info.get('version', VERSION),
                    'sha256': latest_info.get('sha256', ''),
                    'binarySize': latest_info.get('binarySize'),
                    'cached_at': time.time(),
                    'cache_date': datetime.utcnow().isoformat()
                }, f)
            log_json("INFO", "Cached binary info for future use")
        except Exception as e:
            log_json("ERROR", "Failed to cache binary info", error=str(e))
        
        return "/usr/local/bin/watchy-slack-monitor", latest_info.get('version', VERSION)
        
    except Exception as e:
        log_json("ERROR", "Failed to ensure binary", error=str(e))
        # For standalone binary, continue execution anyway
        return "/usr/local/bin/watchy-slack-monitor", VERSION

def fetch_slack_status(api_url: str) -> Dict[str, Any]:
    """
    Fetch Slack status from status API
    """
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
    """
    Remove HTML tags from a string and clean up formatting
    """
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
    """
    Parse Slack API datetime string to datetime object
    Expected format: 2025-07-26T17:53:27-07:00
    """
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
        return datetime.utcnow()

def is_within_polling_interval(note_time: datetime, polling_interval_minutes: int = 5) -> bool:
    """
    Check if a note timestamp is within the last polling interval
    """
    now = datetime.utcnow().replace(tzinfo=note_time.tzinfo)
    cutoff_time = now - timedelta(minutes=polling_interval_minutes)
    return note_time >= cutoff_time

def publish_incident_logs(incidents: List[Dict], log_group: str = '/watchy/slack/status', polling_interval: int = 5):
    """
    Publish incident notes to CloudWatch Logs
    Only publishes notes that are within the polling interval
    """
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
            log_json("WARN", "Failed to create log group", log_group=log_group, error=str(e))
        
        # Create log stream with timestamp
        log_stream = f"slack-incidents-{int(time.time())}"
        try:
            logs_client.create_log_stream(
                logGroupName=log_group,
                logStreamName=log_stream
            )
        except logs_client.exceptions.ResourceAlreadyExistsException:
            pass  # Log stream already exists
        
        logs_published = 0
        log_events = []
        
        for incident in incidents:
            incident_id = incident.get('id', 'unknown')
            incident_title = incident.get('title', 'Unknown Incident')
            incident_url = incident.get('url', '')
            incident_services = incident.get('services', [])
            
            log_json("INFO", "Processing incident", 
                    incident_id=incident_id, 
                    incident_title=incident_title)
            
            notes = incident.get('notes', [])
            
            for note in notes:
                note_body = note.get('body', '')
                note_date_str = note.get('date_created', '')
                
                if not note_body or not note_date_str:
                    continue
                
                # Parse note timestamp
                note_time = parse_datetime(note_date_str)
                
                # Check if note is within polling interval
                if not is_within_polling_interval(note_time, polling_interval):
                    log_json("DEBUG", "Skipping old note", 
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
                    'incident_url': incident_url,
                    'affected_services': incident_services,
                    'note_body': clean_note,
                    'source': 'watchy-slack-monitor'
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
        
        # Publish log events to CloudWatch if we have any
        if log_events:
            # Sort events by timestamp (CloudWatch requirement)
            log_events.sort(key=lambda x: x['timestamp'])
            
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
            log_json("INFO", "No incident logs to publish within polling interval")
        
        return logs_published
        
    except Exception as e:
        log_json("ERROR", "Failed to publish incident logs", 
                error=str(e),
                log_group=log_group,
                incidents_count=len(incidents))
        return 0

def parse_slack_services(status_data: Dict[str, Any]) -> Dict[str, int]:
    """
    Parse Slack service statuses and convert to numeric values for CloudWatch
    """
    try:
        services = status_data.get('status', {})
        
        # Status mapping: operational=0, degraded_performance=1, partial_outage=2, major_outage=3
        status_map = {
            'operational': 0,
            'degraded_performance': 1,
            'partial_outage': 2,
            'major_outage': 3
        }
        
        metrics = {}
        
        # Extract individual service statuses
        for service_name, service_data in services.items():
            if isinstance(service_data, dict) and 'status' in service_data:
                status = service_data['status']
                metrics[service_name] = status_map.get(status, 3)  # Default to major_outage
                print(f"📊 {service_name}: {status} (metric: {metrics[service_name]})")
        
        # Add overall API response metric
        metrics['APIResponse'] = 200 if status_data else 500
        
        return metrics
        
    except Exception as e:
        print(f"❌ Failed to parse Slack services: {e}")
        return {'APIResponse': 500}

def publish_cloudwatch_metrics(metrics: Dict[str, int], namespace: str = 'Watchy/Slack'):
    """
    Publish metrics to CloudWatch
    """
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
                'Timestamp': datetime.utcnow()
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

def main():
    """
    Main execution function for Slack status monitoring
    """
    start_time = time.time()
    
    try:
        print(f"🚀 Watchy Slack Monitor v{VERSION} starting...")
        print(f"📅 Build Date: {BUILD_DATE}")
        print("🏗️  Binary Type: Nuitka Native")
        
        # Get configuration from environment variables with defaults
        api_url = os.getenv('API_URL', 'https://status.slack.com/api/v2.0.0/current')
        namespace = os.getenv('CLOUDWATCH_NAMESPACE', 'Watchy/Slack')
        log_group = os.getenv('CLOUDWATCH_LOG_GROUP', '/watchy/slack/status')
        polling_interval = int(os.getenv('POLLING_INTERVAL_MINUTES', '5'))
        
        print(f"⚙️ Config: Log Group={log_group}, Polling Interval={polling_interval}min")
        
        # Fetch Slack status
        status_data = fetch_slack_status(api_url)
        
        # Parse active incidents and publish logs
        active_incidents = status_data.get('active_incidents', [])
        logs_published = publish_incident_logs(active_incidents, log_group, polling_interval)
        
        # Parse service statuses
        metrics = parse_slack_services(status_data)
        
        # Publish to CloudWatch
        publish_cloudwatch_metrics(metrics, namespace)
        
        # Determine if any services are down
        service_incidents = sum(1 for value in metrics.values() if value >= 2)  # partial_outage or worse
        
        # Send notification if needed
        if service_incidents > 0 or len(active_incidents) > 0:
            if len(active_incidents) > 0:
                incident_titles = [inc.get('title', 'Unknown') for inc in active_incidents]
                message = f"Slack Status Alert: {len(active_incidents)} active incident(s): {', '.join(incident_titles)}"
            else:
                message = f"Slack Status Alert: {service_incidents} service(s) experiencing issues"

        # Execution summary
        execution_time = time.time() - start_time
        
        result = {
            'success': True,
            'message': 'Slack status monitoring completed successfully',
            'metrics_published': len(metrics),
            'active_incidents': len(active_incidents),
            'incident_logs_published': logs_published,
            'service_incidents': service_incidents,
            'execution_time': round(execution_time, 2),
            'timestamp': datetime.utcnow().isoformat(),
            'binary_type': 'nuitka',
            'saas_app': 'Slack'
        }
        
        print(f"✅ Monitoring completed in {execution_time:.2f}s")
        print(f"📊 Published {len(metrics)} metrics")
        print(f"� Published {logs_published} incident logs")
        print(f"�🚨 Active incidents: {len(active_incidents)}")
        print(f"🔧 Service incidents: {service_incidents}")
        
        # Output JSON for Lambda to parse
        print(json.dumps(result))
        
        return 0
        
    except Exception as e:
        execution_time = time.time() - start_time
        error_msg = f"Slack monitoring failed: {str(e)}"
        print(f"❌ {error_msg}")
        
        result = {
            'success': False,
            'error': error_msg,
            'execution_time': round(execution_time, 2),
            'timestamp': datetime.utcnow().isoformat(),
            'saas_app': 'Slack'
        }
        
        print(json.dumps(result))
        return 1

if __name__ == '__main__':
    exit_code = main()
    sys.exit(exit_code)
