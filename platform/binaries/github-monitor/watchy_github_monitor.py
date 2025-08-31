#!/usr/bin/env python3
"""
Watchy GitHub Monitor - Nuitka Source
=====================================

Native binary source for GitHub service monitoring.
Compiles to native executable for maximum protection.

Features:
- GitHub API status monitoring
- Git operations monitoring  
- Repository activity tracking
- CloudWatch metrics publishing
- SNS alerting on issues

SaaS App: GitHub
Compilation: Nuitka native binary
"""

import json
import os
import sys
import time
import hashlib
import logging
from datetime import datetime, timezone
from typing import Dict, Tuple, Any

# AWS SDK (available in Lambda runtime)
import boto3

# Standard library imports for HTTP and validation
import urllib.request
import urllib.parse
import urllib.error
import ssl

# Application configuration
VERSION = "1.0.0-nuitka"
BUILD_DATE = "2025-07-28T05:08:45Z"
SAAS_APP = "GitHub"
BINARY_TYPE = "nuitka"

# GitHub service monitoring configuration
GITHUB_SERVICES = {
    "api": {
        "name": "GitHub API",
        "endpoint": "https://api.github.com/rate_limit",
        "timeout": 10,
        "critical": True
    },
    "git_operations": {
        "name": "Git Operations",
        "endpoint": "https://api.github.com/repos/octocat/Hello-World",
        "timeout": 15,
        "critical": True
    },
    "packages": {
        "name": "GitHub Packages",
        "endpoint": "https://api.github.com/user/packages",
        "timeout": 10,
        "critical": False
    },
    "actions": {
        "name": "GitHub Actions",
        "endpoint": "https://api.github.com/repos/octocat/Hello-World/actions/runs",
        "timeout": 15,
        "critical": True
    },
    "pages": {
        "name": "GitHub Pages",
        "endpoint": "https://api.github.com/repos/octocat/Hello-World/pages",
        "timeout": 10,
        "critical": False
    }
}


class WatchyGitHubMonitor:
    """Main GitHub monitoring class with CloudWatch integration."""
    
    def __init__(self):
        """Initialize the GitHub monitor with AWS clients and configuration."""
        self.version = VERSION
        self.build_date = BUILD_DATE
        self.saas_app = SAAS_APP
        
        # Configure logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        # Initialize AWS clients
        try:
            self.cloudwatch = boto3.client('cloudwatch')
            self.sns = boto3.client('sns')
            self.ssm = boto3.client('ssm')
            self.logger.info("AWS clients initialized successfully")
        except Exception as e:
            self.logger.error(f"Failed to initialize AWS clients: {e}")
            raise
        
        # Load configuration from environment and Parameter Store
        self.config = self._load_configuration()
        
        self.logger.info(f"Watchy GitHub Monitor v{self.version} initialized")
    
    def _load_configuration(self) -> Dict[str, Any]:
        """Load configuration from environment variables and Parameter Store."""
        config = {}
        
        # Load from environment variables
        config['sns_topic_arn'] = os.environ.get('WATCHY_SNS_TOPIC_ARN')
        config['customer_id'] = os.environ.get('WATCHY_CUSTOMER_ID')
        
        # Load API keys from Parameter Store
        try:
            param_name = f"/watchy/api-keys/{config['customer_id']}"
            response = self.ssm.get_parameter(Name=param_name, WithDecryption=True)
            api_keys = json.loads(response['Parameter']['Value'])
            config['github_token'] = api_keys.get('github_token')
            
            self.logger.info("Configuration loaded from Parameter Store")
        except Exception as e:
            self.logger.error(f"Failed to load configuration: {e}")
            raise
        
        return config
    
    def _get_instance_id(self) -> str:
        """Generate a unique instance ID for identification."""
        # Use customer ID and function name for instance identification
        instance_data = f"{self.config.get('customer_id', 'unknown')}-github-monitor"
        return hashlib.sha256(instance_data.encode()).hexdigest()[:16]
    
    def _check_github_service(self, service_key: str, service_config: Dict) -> Tuple[bool, float, str]:
        """Check a single GitHub service endpoint."""
        start_time = time.time()
        
        try:
            # Prepare request with GitHub token if available
            headers = {
                'User-Agent': f'Watchy-GitHub-Monitor/{self.version}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            if self.config.get('github_token'):
                headers['Authorization'] = f'token {self.config["github_token"]}'
            
            req = urllib.request.Request(
                service_config['endpoint'],
                headers=headers
            )
            
            # Create SSL context
            ssl_context = ssl.create_default_context()
            
            # Make request
            with urllib.request.urlopen(req, timeout=service_config['timeout'], context=ssl_context) as response:
                response_time = time.time() - start_time
                
                if response.status == 200:
                    # Try to parse response for additional validation
                    try:
                        data = json.loads(response.read().decode('utf-8'))
                        self.logger.debug(f"GitHub {service_key} response: {len(str(data))} chars")
                    except Exception:
                        pass  # Response parsing is optional
                    
                    self.logger.info(f"GitHub {service_config['name']} check passed ({response_time:.2f}s)")
                    return True, response_time, "OK"
                else:
                    self.logger.warning(f"GitHub {service_config['name']} returned status {response.status}")
                    return False, response_time, f"HTTP {response.status}"
        
        except urllib.error.HTTPError as e:
            response_time = time.time() - start_time
            error_msg = f"HTTP {e.code}: {e.reason}"
            self.logger.error(f"GitHub {service_config['name']} HTTP error: {error_msg}")
            return False, response_time, error_msg
        
        except urllib.error.URLError as e:
            response_time = time.time() - start_time
            error_msg = f"Connection error: {e.reason}"
            self.logger.error(f"GitHub {service_config['name']} connection error: {error_msg}")
            return False, response_time, error_msg
        
        except Exception as e:
            response_time = time.time() - start_time
            error_msg = f"Unexpected error: {str(e)}"
            self.logger.error(f"GitHub {service_config['name']} unexpected error: {error_msg}")
            return False, response_time, error_msg
    
    def _publish_cloudwatch_metrics(self, service_results: Dict[str, Tuple[bool, float, str]]) -> None:
        """Publish monitoring metrics to CloudWatch."""
        timestamp = datetime.now(timezone.utc)
        metrics = []
        
        # Overall service availability
        total_services = len(service_results)
        available_services = sum(1 for result in service_results.values() if result[0])
        availability_percentage = (available_services / total_services) * 100
        
        # Add overall availability metric
        metrics.append({
            'MetricName': 'ServiceAvailability',
            'Value': availability_percentage,
            'Unit': 'Percent',
            'Timestamp': timestamp,
            'Dimensions': [
                {'Name': 'SaaSApp', 'Value': 'GitHub'},
                {'Name': 'MonitorType', 'Value': 'Overall'}
            ]
        })
        
        # Add individual service metrics
        for service_key, (is_available, response_time, status) in service_results.items():
            service_config = GITHUB_SERVICES[service_key]
            
            # Availability metric
            metrics.append({
                'MetricName': 'ServiceAvailability',
                'Value': 100.0 if is_available else 0.0,
                'Unit': 'Percent',
                'Timestamp': timestamp,
                'Dimensions': [
                    {'Name': 'SaaSApp', 'Value': 'GitHub'},
                    {'Name': 'Service', 'Value': service_config['name']},
                    {'Name': 'Critical', 'Value': str(service_config['critical'])}
                ]
            })
            
            # Response time metric
            metrics.append({
                'MetricName': 'ResponseTime',
                'Value': response_time * 1000,  # Convert to milliseconds
                'Unit': 'Milliseconds',
                'Timestamp': timestamp,
                'Dimensions': [
                    {'Name': 'SaaSApp', 'Value': 'GitHub'},
                    {'Name': 'Service', 'Value': service_config['name']}
                ]
            })
        
        # Publish metrics to CloudWatch
        try:
            # Split metrics into batches of 20 (CloudWatch limit)
            for i in range(0, len(metrics), 20):
                batch = metrics[i:i+20]
                self.cloudwatch.put_metric_data(
                    Namespace='Watchy/GitHub',
                    MetricData=batch
                )
            
            self.logger.info(f"Published {len(metrics)} metrics to CloudWatch")
        
        except Exception as e:
            self.logger.error(f"Failed to publish CloudWatch metrics: {e}")
    
    def _send_alert(self, service_results: Dict[str, Tuple[bool, float, str]]) -> None:
        """Send SNS alert if critical services are down."""
        if not self.config.get('sns_topic_arn'):
            return
        
        failed_critical_services = []
        failed_non_critical_services = []
        
        for service_key, (is_available, response_time, status) in service_results.items():
            if not is_available:
                service_config = GITHUB_SERVICES[service_key]
                if service_config['critical']:
                    failed_critical_services.append({
                        'name': service_config['name'],
                        'status': status,
                        'response_time': response_time
                    })
                else:
                    failed_non_critical_services.append({
                        'name': service_config['name'],
                        'status': status,
                        'response_time': response_time
                    })
        
        # Send alert only if critical services are down
        if failed_critical_services:
            alert_message = {
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'saas_app': 'GitHub',
                'alert_type': 'service_outage',
                'severity': 'critical',
                'failed_critical_services': failed_critical_services,
                'failed_non_critical_services': failed_non_critical_services,
                'customer_id': self.config.get('customer_id'),
                'monitor_version': self.version
            }
            
            try:
                self.sns.publish(
                    TopicArn=self.config['sns_topic_arn'],
                    Subject="🚨 Watchy Alert: GitHub Critical Services Down",
                    Message=json.dumps(alert_message, indent=2)
                )
                
                self.logger.warning(f"Alert sent: {len(failed_critical_services)} critical GitHub services down")
            
            except Exception as e:
                self.logger.error(f"Failed to send SNS alert: {e}")
    
    def monitor_github_services(self) -> Dict[str, Any]:
        """Monitor all GitHub services and return results."""
        self.logger.info("Starting GitHub services monitoring check")
        
        service_results = {}
        
        # Check each GitHub service
        for service_key, service_config in GITHUB_SERVICES.items():
            self.logger.info(f"Checking GitHub {service_config['name']}...")
            is_available, response_time, status = self._check_github_service(service_key, service_config)
            service_results[service_key] = (is_available, response_time, status)
        
        # Publish metrics to CloudWatch
        self._publish_cloudwatch_metrics(service_results)
        
        # Send alerts if needed
        self._send_alert(service_results)
        
        # Prepare response
        total_services = len(service_results)
        available_services = sum(1 for result in service_results.values() if result[0])
        
        response = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'saas_app': 'GitHub',
            'monitor_version': self.version,
            'total_services': total_services,
            'available_services': available_services,
            'availability_percentage': (available_services / total_services) * 100,
            'service_details': {
                service_key: {
                    'name': GITHUB_SERVICES[service_key]['name'],
                    'available': result[0],
                    'response_time_ms': round(result[1] * 1000, 2),
                    'status': result[2],
                    'critical': GITHUB_SERVICES[service_key]['critical']
                }
                for service_key, result in service_results.items()
            }
        }
        
        self.logger.info(f"GitHub monitoring completed: {available_services}/{total_services} services available")
        return response


def lambda_handler(event, context):
    """AWS Lambda entry point for GitHub monitoring."""
    try:
        monitor = WatchyGitHubMonitor()
        result = monitor.monitor_github_services()
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    
    except Exception as e:
        error_response = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'error': str(e),
            'saas_app': 'GitHub',
            'monitor_version': VERSION
        }
        
        print(f"ERROR: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(error_response)
        }


def main():
    """Main entry point for direct execution (testing)."""
    try:
        monitor = WatchyGitHubMonitor()
        result = monitor.monitor_github_services()
        print(json.dumps(result, indent=2))
        
    except KeyboardInterrupt:
        print("\nMonitoring interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
