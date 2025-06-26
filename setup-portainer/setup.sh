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
