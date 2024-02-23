#!/bin/sh -x


#https://labs.play-with-docker.com/p/cnc4pos7vdo000fmvufg#cnc4pos7_cnc4prk7vdo000fmvugg
id: DockerChallenge2024
pwd:DockerChallenge2024

# with shell or bash script
# create a container of grafana
# create create a container of prometheus
# all containers should be persistant 
# only grafana can be called from outside the host serevr
# go to $GARAFANA_URL/connections/add-new-connection
# use admin/admin credentials then foobar as new pwd
# select prometheus / set Connection / SAVe &Test

prom_volume_name="prom_volume"
grafana_volume_name="grafana_volume"

network_name="back-end"

docker volume create $prom_volume_name
docker volume create $grafana_volume_name

docker volume list

docker network create $network_name || true

docker stop prometheus || true
docker stop grafana || true

docker rm prometheus || true
docker rm grafana || true

docker run -d --network="$network_name" -v $prom_volume_name:/prometheus --name=prometheus prom/prometheus
docker run -d -p 3001:3000 --network="$network_name" -v $grafana_volume_name:/var/lib/grafana --name=grafana grafana/grafana-enterprise

docker ps
