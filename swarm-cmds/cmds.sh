docker swarm init --advertise-addr 51.21.x.x


docker swarm join --token <token> 51.21.x.x:2377 --advertise-addr 13.48.249.45




docker service ls


docker service ps my-nginx


sudo systemctl stop docker


watch docker service ps my-nginx



docker service rm my-nginx

docker service logs myapp_app

docker service ls
docker stack ls



# Run this on manager and both workers:
echo token-key | docker login ghcr.io -u incrisz --password-stdin


# Create a Docker Compose File for the Stack
nano docker-stack.yml


docker stack deploy -c docker-stack.yml myapp


docker stack services myapp


docker stack ps myapp

docker service logs myapp_app
# on workers
docker swarm leave

# on manager
docker swarm leave --force



docker network inspect joy_app_network

# ALL manager node
docker network create \
  --driver overlay \
  --attachable \
  portainer_agent_network



docker service create \
  --name portainer \
  --publish 9000:9000 \
  --publish 9443:9443 \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  --network portainer_agent_network \
  portainer/portainer-ce:latest \
  -H unix:///var/run/docker.sock



docker service create \
  --name portainer_agent \
  --mode global \
  --network portainer_agent_network \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=bind,src=/var/lib/docker/volumes,dst=/var/lib/docker/volumes \
  portainer/agent:latest




docker inspect <container_name_or_id> | grep "IPAddress"





apt update
apt install -y iputils-ping netcat-openbsd dnsutils telnet
