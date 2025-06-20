# Portainer Docker Swarm Setup Guide

You've successfully deployed Portainer for Docker Swarm management! Here's what each step accomplished and how to use it effectively.

## 🚀 What You've Deployed

Your Portainer setup includes:
- **Portainer Server** (on manager node) - Web UI and management
- **Portainer Agent** (on all nodes) - Collects data from each node
- **Overlay Network** - Secure communication between components

## 📋 Setup Commands Explained

### Step 1: Deploy Portainer Server
```bash
docker service create \
  --name portainer \
  --publish 9000:9000 \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  portainer/portainer-ce \
  --admin-password='12345678901234'
```
**What it does:**
- Creates Portainer server on manager node only
- Exposes web interface on port 9000
- Mounts Docker socket for local management
- Sets admin password to avoid setup wizard

### Step 2: Clean Up Old Agent (if exists)
```bash
sudo docker service rm portainer_agent
```
**What it does:** Removes any existing agent to avoid conflicts

### Step 3: Create Overlay Network
```bash
sudo docker network create \
  --driver=overlay \
  --attachable \
  portainer_agent_network
```
**What it does:** Creates secure overlay network for agent communication

### Step 4: Connect Portainer to Agent Network
```bash
sudo docker service update \
  --network-add portainer_agent_network \
  portainer
```
**What it does:** Adds Portainer server to the agent network

### Step 5: Deploy Portainer Agent
```bash
sudo docker service create \
  --name portainer_agent \
  --mode global \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=bind,src=/,dst=/host \
  --env AGENT_CLUSTER_ADDR=tasks.portainer_agent \
  portainer/agent
```
**What it does:**
- Deploys agent on ALL nodes (global mode)
- Provides access to Docker socket and host filesystem
- Enables cluster communication

### Step 6: Verify Agent Deployment
```bash
sudo docker service ps portainer_agent
```
**What it does:** Shows agent running on each node

## 🌐 Accessing Portainer

1. **Open browser and navigate to:** `http://<your-manager-ip>:9000`
2. **Login with:**
   - Username: `admin`
   - Password: `12345678901234`

## 🔧 Initial Portainer Configuration

### Connect to Docker Swarm Environment

1. **After login, go to:** Settings → Environments
2. **Click:** "Add environment"
3. **Select:** "Docker Swarm"
4. **Configure:**
   - Name: `Docker Swarm`
   - Endpoint URL: `tasks.portainer_agent:9001`
   - Public IP: `<your-manager-ip>`

## 📊 What You Can Do with Portainer

### Service Management
- **View all services** in your swarm
- **Scale services** up/down with sliders
- **Update service configurations**
- **View service logs** in real-time
- **Deploy new services** with GUI

### Stack Management
- **Deploy stacks** from docker-compose files
- **Manage existing stacks** (your php-app stack)
- **View stack services** and their distribution
- **Update stack configurations**

### Node Management
- **View all swarm nodes** and their status
- **Monitor node resources** (CPU, Memory, Disk)
- **Manage node labels** and constraints
- **Drain/activate nodes** for maintenance

### Network & Volume Management
- **View overlay networks**
- **Create new networks**
- **Manage volumes** across the swarm
- **Monitor network traffic**

## 🎯 Deploy Your PHP App via Portainer

1. **Go to:** Stacks → Add stack
2. **Name:** `php-application`
3. **Copy your compose file** into the web editor
4. **Click:** Deploy the stack
5. **Monitor** deployment in real-time

## 📈 Monitoring Commands

```bash
# Check Portainer server status
sudo docker service ps portainer

# Check agent status on all nodes
sudo docker service ps portainer_agent

# View Portainer logs
sudo docker service logs portainer

# View agent logs
sudo docker service logs portainer_agent

# Check network connectivity
sudo docker network ls | grep portainer
```

## 🔒 Security Improvements

### Change Default Password
1. Go to **Users** → **admin**
2. Click **Change password**
3. Set a strong password

### Enable HTTPS (Recommended for Production)
```bash
# Stop current Portainer
sudo docker service rm portainer

# Create SSL certificates directory
sudo mkdir -p /opt/portainer/ssl

# Generate self-signed certificate (or use your own)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/portainer/ssl/portainer.key \
  -out /opt/portainer/ssl/portainer.crt

# Deploy with HTTPS
docker service create \
  --name portainer \
  --publish 9443:9443 \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  --mount type=bind,src=/opt/portainer/ssl,dst=/ssl \
  --network portainer_agent_network \
  portainer/portainer-ce \
  --admin-password='your-secure-password' \
  --ssl \
  --sslcert /ssl/portainer.crt \
  --sslkey /ssl/portainer.key
```

## 🛠️ Troubleshooting

### Agent Not Connecting
```bash
# Check agent network connectivity
sudo docker exec -it $(sudo docker ps -q -f name=portainer_agent) ping tasks.portainer_agent

# Restart agent service
sudo docker service update --force portainer_agent
```

### Portainer Not Accessible
```bash
# Check if port is open
sudo netstat -tlnp | grep :9000

# Check firewall
sudo ufw status

# Allow port if needed
sudo ufw allow 9000/tcp
```

### View Detailed Logs
```bash
# Portainer server logs
sudo docker service logs --follow portainer

# Agent logs from specific node
sudo docker service logs --follow portainer_agent
```

## 🎛️ Useful Portainer Features

### Templates
- Pre-built application templates
- One-click deployments
- Custom template creation

### Registries
- Connect to private registries
- Manage image repositories
- Automated pulling

### Users & Teams
- Role-based access control
- Team management
- Resource restrictions

### Webhooks
- Automated deployments
- CI/CD integration
- Service updates

## 📱 Mobile Access

Portainer's web interface is mobile-responsive, so you can manage your Docker Swarm from your phone or tablet by accessing `http://<your-manager-ip>:9000`

## 🔄 Updating Portainer

```bash
# Update Portainer server
sudo docker service update --image portainer/portainer-ce:latest portainer

# Update agents
sudo docker service update --image portainer/agent:latest portainer_agent
```

Your Portainer setup is now complete and ready for production use! 🎉