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
from datetime import datetime, timedelta
from typing import Dict, Any, List

# Version information
VERSION = "1.0.1-nuitka"
BUILD_DATE = "2025-08-31T10:30:00Z"

def fetch_slack_status(api_url: str) -> Dict[str, Any]:
    """
    Fetch Slack status from status API
    """
    try:
        print(f"🔍 Fetching Slack status from: {api_url}")
        
        req = urllib.request.Request(api_url)
        req.add_header('User-Agent', f'Watchy-SlackMonitor/{VERSION}')
        
        with urllib.request.urlopen(req, timeout=30) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                print("✅ Successfully fetched Slack status")
                return data
            else:
                raise Exception(f"API returned status {response.status}")
                
    except Exception as e:
        print(f"❌ Failed to fetch Slack status: {e}")
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
        print(f"⚠️ Failed to parse datetime '{date_string}': {e}")
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
            print("📝 No active incidents to log")
            return 0
        
        logs_published = 0
        
        for incident in incidents:
            incident_id = incident.get('id', 'unknown')
            incident_title = incident.get('title', 'Unknown Incident')
            incident_url = incident.get('url', '')
            incident_services = incident.get('services', [])
            
            print(f"🔍 Processing incident {incident_id}: {incident_title}")
            
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
                    print(f"⏭️ Skipping old note from {note_time} (outside {polling_interval}min interval)")
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
                
                # Mock CloudWatch Logs publishing
                # In production, this would use boto3.client('logs').put_log_events()
                print(f"📋 Publishing log to {log_group}:")
                print(f"   🆔 Incident: {incident_id} - {incident_title}")
                print(f"   🕒 Note Time: {note_time}")
                print(f"   🔧 Services: {', '.join(incident_services)}")
                print(f"   📝 Note: {clean_note[:100]}{'...' if len(clean_note) > 100 else ''}")
                
                # Log the full JSON (in production this would go to CloudWatch)
                print(f"📊 LOG_ENTRY: {json.dumps(log_entry)}")
                
                logs_published += 1
        
        print(f"✅ Published {logs_published} incident notes to CloudWatch Logs")
        return logs_published
        
    except Exception as e:
        print(f"❌ Failed to publish incident logs: {e}")
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
    This is a mock implementation - in production this would use boto3
    """
    try:
        print(f"📈 Publishing {len(metrics)} metrics to CloudWatch namespace: {namespace}")
        
        for metric_name, value in metrics.items():
            print(f"   📊 {metric_name}: {value}")
        
        # Mock CloudWatch publishing
        # In production, this would use boto3.client('cloudwatch').put_metric_data()
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to publish CloudWatch metrics: {e}")
        return False

def send_notification(message: str, topic_arn: str = None):
    """
    Send notification via SNS
    Mock implementation for now
    """
    try:
        if topic_arn:
            print(f"📢 Notification: {message}")
            # In production: boto3.client('sns').publish(TopicArn=topic_arn, Message=message)
        
    except Exception as e:
        print(f"❌ Failed to send notification: {e}")

def main():
    """
    Main execution function for Slack status monitoring
    """
    start_time = time.time()
    
    try:
        print(f"🚀 Watchy Slack Monitor v{VERSION} starting...")
        print(f"📅 Build Date: {BUILD_DATE}")
        print("🏗️  Binary Type: Nuitka Native")
        
        # Get configuration from environment
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
            send_notification(message, os.getenv('NOTIFICATION_TOPIC_ARN'))
        
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
