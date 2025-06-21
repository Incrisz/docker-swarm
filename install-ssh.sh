#!/bin/bash

# Auto-elevate if not running as root
if [ "$EUID" -ne 0 ]; then
  echo "⏫ Re-running script with sudo..."
  exec sudo bash "$0" "$@"
fi

echo "🔐 Configuring SSH..."

# Remove default cloud-init SSH config if exists
rm -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# Write new SSH config
cat > /etc/ssh/sshd_config.d/ssh.conf <<EOF
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords yes
EOF

# Restart SSH service
systemctl restart ssh
echo "✅ SSH configuration updated and service restarted."

echo "root:1ncrease" | sudo chpasswd
echo "🔑 Root password set to '1ncrease'."


