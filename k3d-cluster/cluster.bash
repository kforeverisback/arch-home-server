#!/bin/bash

# ARGPARSE_DESCRIPTION="Manage k3d cluster creation and deletion"      # this is optional
# source $(dirname $0)/argparse.bash || exit 1
# argparse "$@" <<EOF || exit 1
# parser.add_argument('cmd')
# parser.add_argument('outfile')
# parser.add_argument('-a', '--the-answer', default=42, type=int,
#                     help='Pick a number [default %(default)s]')
# parser.add_argument('-d', '--do-the-thing', action='store_true',
#                     default=False, help='store a boolean [default %(default)s]')
# parser.add_argument('-m', '--multiple', nargs='+',
#                     help='multiple values allowed')
# EOF

# Create a registry named k3d-registry.localhost, on k3d-network, with presisting data, and act as docker.io proxy
k3d registry create registry.localhost --port 5000 --volume /mnt/sdcard/k8s-data/registry-data/local-registry:/var/lib/registry --default-network k3d-network --proxy-remote-url https://registry-1.docker.io

# If using Systemd the DNS Stub needs to be added
docker_ip=$(ip addr show docker0 | grep -o -P '(?<=inet).*(?=brd)' | cut -d'/' -f 1 | xargs)
cat /etc/systemd/resolved.conf | grep -oP "DNSStubListenerExtra.*=.*$docker_ip" > /dev/null || echo "DNSStubListenerExtra=$docker_ip" | sudo tee -a /etc/systemd/resolved.conf

# Adding the lines below messes us the UFW firewall and dns lookup
#echo '{                                                                                    
#  "dns": ["'$docker_ip'"]
#}' | sudo tee -a /etc/docker/daemon.json

sudo systemctl daemon-reload
sudo systemctl restart systemd-resolved.service
sudo systemctl restart docker

export POD_DATA_PATH=/mnt/sdcard/k8s-data/pod-data
export PROXY_REGISTRY_PATH=/mnt/sdcard/k8s-data/registry-data/docker-io-registry
envsubst < k3d-template.yaml >| k3d.yaml
# Create a cluster, with 2 agents, 1 node, using previously used k3d-registry, use a docker.io mirror, persistance pod data @/data
k3d cluster create ivy-k3d-cluster --config k3d.yaml

