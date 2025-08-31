#!/usr/bin/env python3
"""
Test script for Slack monitor - runs the Python directly without binary download
"""

import os
import sys

# Set up test environment
os.environ['WATCHY_LICENSE_KEY'] = 'lemon_test_key_12345678'
os.environ['API_URL'] = 'https://status.slack.com/api/v2.0.0/current'
os.environ['CLOUDWATCH_NAMESPACE'] = 'Watchy/Slack'
os.environ['CLOUDWATCH_LOG_GROUP'] = '/watchy/slack/status'
os.environ['POLLING_INTERVAL_MINUTES'] = '5'

# Add the binary directory to path so we can import the monitor
sys.path.insert(0, 'platform/binaries/slack-monitor')

# Import and run the monitor
from watchy_slack_monitor import main

if __name__ == '__main__':
    print("🧪 Testing Slack Monitor locally...")
    exit_code = main()
    print(f"\n🏁 Test completed with exit code: {exit_code}")
