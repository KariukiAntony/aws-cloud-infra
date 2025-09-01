#! /bin/bash

# --- Configurations ----

# Cloudwatch Agent config path
CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/config.json"
LOG_FILE="/var/log/health-check.log"
SCRIPT_PATH="/usr/local/bin/health-check.sh"

# Update and upgrade the package index
sudo apt update && sudo apt dist-upgrade -y
sudo apt install -y nginx unzip stress-ng
sudo apt enable nginx

sudo hostnamectl set-hostname "${hostname}"
echo "127.0.1.1 ${hostname}" | sudo tee -a /etc/hosts

# Install the AWS cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Get the instance ID
export TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Create a simple web page
cat <<-EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${base_name}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background-color: #f0f8ff;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 { color: #2c3e50; margin-bottom: 30px; }
        .header { background-color: #f0f0f0; padding: 20px; text-align: center; }
        .status { color: #27ae60; font-weight: bold; font-size: 18px; }
        .info { margin: 20px 0; padding: 15px; background: #ecf0f1; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Production Application Server</h1>
        <div class="header">
            <h1>${base_name}-$INSTANCE_ID</h1>
        </div>
        <div class="status">Server is running successfully!</div>
        <div class="info">
            <strong>Monitoring Status:</strong><br>
            • CloudWatch Agent: Active<br>
            • SNS Alerts: Configured<br>
            • Detailed Monitoring: Enabled
        </div>
        <p>This server is monitored with comprehensive CloudWatch alarms for CPU, memory, disk usage, and system health.</p>
        <small>Hostname: $(hostname) | Date: $(date +"%Y-%m-%d %T")</small>
        <p>Instance ID: $INSTANCE_ID </p>
    </div>
</body>
</html>
EOF
sudo systemctl restart nginx

# Install the cloudwatch Agent
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i ./amazon-cloudwatch-agent.deb

cat <<-EOF | sudo tee "$CONFIG_PATH"
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "$LOG_FILE",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/var/log/health-check.log",
                        "timestamp_format": "%b %d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/var/log/nginx/access.log",
                        "timestamp_format": "[%d/%b/%Y:%H:%M:%S %z]"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "${log_group_name}",
                        "log_stream_name": "{instance_id}/var/log/nginx/error.log",
                        "timestamp_format": "[%a %b %d %H:%M:%S %Y]"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "append_dimensions": {
            "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}",
            "InstanceId": "\$${aws:InstanceId}"
        },
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent",
                    "inodes_free"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time",
                    "reads",
                    "writes",
                    "read_bytes",
                    "write_bytes"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent",
                    "mem_available_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start the agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c "file:$CONFIG_PATH" \
    -s

# Enable CloudWatch agent to start on boot
systemctl enable amazon-cloudwatch-agent

# Simple health check script
cat <<-EOF | sudo tee "$SCRIPT_PATH"
#!/bin/bash

TIMESTAMP=\$(date +"%Y-%m-%d %T")
LOG_FILE="$LOG_FILE"

# Check if nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "\$TIMESTAMP: NGINX service is running" | sudo tee -a "\$LOG_FILE"
    HTTP_STATUS="OK"
else
    echo "\$TIMESTAMP: NGINX service is NOT running" | sudo tee -a "\$LOG_FILE"
    HTTP_STATUS="FAILED"
    sudo systemctl restart nginx
fi

# Check disk space
DISK_USAGE=\$(df / | tail -1 | awk '{print \$5}' | sed 's/%//')
if [[ \$DISK_USAGE -gt 90 ]]; then
    echo "\$TIMESTAMP: WARNING - Disk usage is at \$DISK_USAGE%" | sudo tee -a "\$LOG_FILE"
else
    echo "\$TIMESTAMP: Disk usage is at \$DISK_USAGE%" | sudo tee -a "\$LOG_FILE"
fi

# Check memory usage
MEM_USAGE=\$(free | grep Mem | awk '{printf("%.2f"), \$3/\$2 * 100.0}')
echo "\$TIMESTAMP: Memory usage is at \$MEM_USAGE%" | sudo tee -a "\$LOG_FILE"

# Check cpu usage.
CPU_USAGE=\$(top -b -n1 | grep "%Cpu(s)" | awk '{print 100-\$8}')
echo "\$TIMESTAMP: CPU usage is at \$CPU_USAGE" | sudo tee -a "\$LOG_FILE"

# Add a new line.
echo | sudo tee -a \$LOG_FILE

EOF

sudo chmod +x "$SCRIPT_PATH"

# Schedule healthcheck to run every 5 minutes.
echo "*/5 * * * * $SCRIPT_PATH" | crontab -

# Run the initial healthcheck.
"$SCRIPT_PATH"

# Pull the latest tag of the backend application.

# ---Test ASG ---
# # Memory stress - 90% memory usage
# stress-ng --vm 4 --vm-bytes 90% --timeout 300s --metrics-brief
# # CPU stress test (4 workers for 5 minutes)
# stress-ng --cpu 4 --timeout 300s --metrics-brief
# # Combined CPU + Memory stress
# stress-ng --cpu 2 --vm 2 --vm-bytes 85% --timeout 300s --metrics-brief