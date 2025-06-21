# All on manager ode

#1
docker service create \
  --name portainer \
  --publish 9000:9000 \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  portainer/portainer-ce \
#   --admin-password='12345678901234'


#2
sudo docker service rm portainer_agent

#3
sudo docker network create \
  --driver=overlay \
  --attachable \
  portainer_agent_network

#4


sudo docker service create \
  --name portainer_agent \
  --mode global \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=bind,src=/,dst=/host \
  --env AGENT_CLUSTER_ADDR=tasks.portainer_agent \
  portainer/agent
#5
sudo docker service update \
  --network-add portainer_agent_network \
  portainer


#6
sudo docker service ps portainer_agent



# urgent removing
docker service rm portainer
docker volume rm portainer_data
docker volume ls | grep portainer_data
docker volume rm -f portainer_data




docker service create \
  --name portainer \
  --publish 9000:9000 \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount type=volume,src=portainer_data,dst=/data \
  portainer/portainer-ce
