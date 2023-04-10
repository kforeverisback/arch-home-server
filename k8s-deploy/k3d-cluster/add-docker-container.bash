#!/bin/bash

### This adds a CoreDNS entry for the docker container running in the same nework as k3d
### .docker.local will be added to the container name as FQDN to hosts file

usage () { echo -e "Container name is empty.\nUsage: ./$0 DKR-CONTAINER-ID-or-NAME" >&2; }

# Cluster Network
[[ -z "$CLUSTER_NETWORK" ]] && CLUSTER_NETWORK=k3d-network

container_name_or_id=$1
echo "Container Name/ID: $container_name_or_id"

[[ -z $container_name_or_id ]] && usage && exit 1

container_ip=$(docker inspect "$container_name_or_id" --format '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
[[ -z $container_ip ]] && echo 'Container IP not found. Make sure the container exists' && exit 1
host_entry="$container_ip ${container_name_or_id}.docker.local"

echo "Container IP: ${container_ip}"
echo "Adding host Entry: ${host_entry}"

host_exists=$(kubectl get cm -n kube-system coredns-custom -o json | jq '.data."NodeHosts.docker.local"' -r | grep -oP "$host_entry")

[[ -n "$host_exists" ]] && echo "^^Host entry exists" && exit 0

kubectl get cm -n kube-system coredns-custom -o json | jq '.data."NodeHosts.docker.local"+="'"${host_entry}"'\n"'

kubectl get cm -n kube-system coredns-custom -o json | jq '.data."NodeHosts.docker.local"+="'"${host_entry}"'\n"' | kubectl apply --dry-run -f -
