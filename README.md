# Docker Swarm Setup Guide

This guide will help you set up Docker and configure Docker Swarm for a multi-node cluster environment.

## Quick Installation

### Automated Installation Script

Run this command on each server where you want to install Docker:

```bash
curl -fsSL https://raw.githubusercontent.com/Incrisz/docker-swarm/main/install-docker.sh | bash
```

**Or download and run manually:**

```bash
wget https://raw.githubusercontent.com/Incrisz/docker-swarm/main/install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
```
### Authenticate Docker to GHCR

```bash
sudo echo <YOUR_GHCR_PAT> | docker login ghcr.io -u <your_github_username> --password-stdin

sudo docker secret create ghcr_auth_config ~/.docker/config.json

```
### update your compose file(app)

```bash
    ports:
      - "8080:80"
    secrets:
      - source: ghcr_auth_config
        target: /root/.docker/config.json

```
### update your compose file(last end)

```bash
secrets:
  ghcr_auth_config:
    external: true

```
### quick debug run

```bash
# 1. Remove the current stack
sudo docker stack rm php-db

# 2. Ensure authentication on ALL swarm nodes
sudo docker login ghcr.io -u incrisz -p ghp_9rPbIZv7AgO7xoN0N49pmoP

# 3. Pre-pull the image on ALL nodes (run on each node)
sudo docker pull ghcr.io/incrisz/ghcr-php:latest

# 4. Use the fixed compose file (without secrets for auth)
sudo docker stack deploy -c php-compose-fixed.yml php-app
```
## What the Script Does

The installation script performs the following actions:

1. **Updates system packages** - Ensures your system is up to date
2. **Installs dependencies** - ca-certificates, curl, gnupg, lsb-release
3. **Adds Docker's GPG key** - For package verification
4. **Sets up Docker repository** - Official Docker APT repository
5. **Installs Docker** - Docker CE, CLI, and containerd
6. **Starts Docker service** - Enables and starts Docker daemon
7. **Configures firewall** - Opens required ports for Docker Swarm
8. **Adds current user to docker group** - Allows running Docker without sudo

## Docker Swarm Configuration

After installing Docker on all your servers, follow these steps to set up your swarm cluster:

### Step 1: Initialize Swarm Manager

On your **manager node** (the server that will control the swarm):

```bash
# Initialize the swarm
docker swarm init --advertise-addr <MANAGER-IP>

# Example:
docker swarm init --advertise-addr 192.168.1.100
```

This command will output a join token that looks like:
```
docker swarm join --token SWMTKN-1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx 192.168.1.100:2377
```

**Save this token** - you'll need it to add worker nodes!

### Step 2: Add Worker Nodes

On each **worker node**, run the join command provided by the manager:

```bash
docker swarm join --token SWMTKN-1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx <MANAGER-IP>:2377
```

### Step 3: Add Additional Manager Nodes (Optional)

For high availability, you can promote worker nodes to managers or add new manager nodes:

```bash
# On the original manager, get the manager join token
docker swarm join-token manager

# This will output a command like:
docker swarm join --token SWMTKN-1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx 192.168.1.100:2377

# Run this command on the server you want to make a manager
```

### Step 4: Verify Your Swarm

On any manager node, check the swarm status:

```bash
# List all nodes in the swarm
docker node ls

# Check swarm info
docker system info | grep -A 10 "Swarm:"
```

## Required Ports

The installation script automatically opens these ports:

| Port | Protocol | Purpose |
|------|----------|---------|
| 2377 | TCP | Swarm management (manager nodes only) |
| 7946 | TCP/UDP | Node communication |
| 4789 | UDP | Overlay network traffic |
| 22 | TCP | SSH access (optional) |

## Common Docker Swarm Commands

### Node Management
```bash
# List all nodes
docker node ls

# Inspect a node
docker node inspect <node-name>

# Promote worker to manager
docker node promote <node-name>

# Remove a node from swarm (run on the node being removed)
docker swarm leave

# Remove a node from swarm (run on manager)
docker node rm <node-name>
```

### Service Management
```bash
# Create a service
docker service create --name my-web --replicas 3 -p 8080:80 nginx

# List services
docker service ls

# Scale a service
docker service scale my-web=5

# Update a service
docker service update --image nginx:latest my-web

# Remove a service
docker service rm my-web
```

### Stack Management
```bash
# Deploy a stack from docker-compose.yml
docker stack deploy -c docker-compose.yml my-stack
# with token
docker stack deploy --with-registry-auth -c test.yml test


# List stacks
docker stack ls

# List services in a stack
docker stack services my-stack

# Remove a stack
docker stack rm my-stack
```

## Troubleshooting

### Common Issues

1. **Firewall blocking connections**
   ```bash
   # Check if UFW is active
   sudo ufw status
   
   # If needed, run the script again or manually open ports
   sudo ufw allow 2377/tcp
   sudo ufw allow 7946/tcp
   sudo ufw allow 7946/udp
   sudo ufw allow 4789/udp
   ```

2. **Docker daemon not running**
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

3. **Permission denied when running docker commands**
   ```bash
   # Add your user to docker group and restart session
   sudo usermod -aG docker $USER
   newgrp docker
   ```

4. **Node communication issues**
   ```bash
   # Check if nodes can reach each other
   ping <other-node-ip>
   telnet <other-node-ip> 2377
   ```

### Getting Join Tokens

If you lose your join tokens:

```bash
# Get worker join token
docker swarm join-token worker

# Get manager join token
docker swarm join-token manager

# Rotate tokens (for security)
docker swarm join-token --rotate worker
```

## Security Best Practices

1. **Use specific IP addresses** when initializing swarm
2. **Rotate join tokens regularly** for enhanced security
3. **Limit manager nodes** to odd numbers (3, 5, 7) for proper quorum
4. **Use TLS certificates** for production environments
5. **Regularly update** Docker and system packages

## Example Multi-Service Stack

Create a `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    deploy:
      replicas: 3
      placement:
        constraints:
          - node.role == worker
  
  api:
    image: node:alpine
    deploy:
      replicas: 2
      placement:
        constraints:
          - node.role == worker
```

Deploy it:
```bash
docker stack deploy -c docker-compose.yml my-app
```

## Support

For issues or questions:
- Check Docker documentation: https://docs.docker.com/engine/swarm/
- Review the installation script: https://github.com/Incrisz/docker-swarm/blob/main/install-docker.sh
- Docker Swarm tutorial: https://docs.docker.com/engine/swarm/swarm-tutorial/

---

**Note:** Make sure to replace `<MANAGER-IP>` with your actual manager node IP address in all commands.
