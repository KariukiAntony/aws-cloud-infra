#! /bin/bash

sudo apt update && sudo apt dist-upgrade -y

sudo hostnamectl set-hostname "${hostname}"
echo "127.0.1.1 ${hostname}" | sudo tee -a /etc/hosts

sudo apt install -y nginx unzip
sudp systemctl enable nginx

# Get the instance ID
export TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

cat <<-EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Nginx</title>
    <style>
        body {font-family: Arial, sans-serif;background-color: #f4f4f9;color: #333;margin: 0;display: flex;justify-content: center;align-items: center;height: 100vh;text-align: center;}
        .container {padding: 20px;border: 1px solid #ddd;border-radius: 8px;box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);background-color: #fff;}
        h1 {color: #555;}
        p {font-size: 1.2em;}
    </style>
</head>
<body>
    <div class="container">
        <h1>Bastion host: ${hostname} up and running!</h1>
        <h3>Instance ID: $INSTANCE_ID.</h3>
    </div>
</body>
</html>
EOF
sudo systemctl restart nginx

# Secure server
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd


# Simple motd
cat <<-EOF | sudo tee /etc/motd
===============================================
  ${hostname}
  $(date)
===============================================
EOF

# Log completion
sudo sh -c 'echo "$(date): User data script completed successfully" >> /var/log/user-data.log'