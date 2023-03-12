# Arch Home Server Install Guide


## Deploying k3d cluster

Use make create to deploy the k3d cluster

The k3d cluster will create
- A docker network
- A registry at port localhost:5000
- A volume would be added to the single docker node
- 20 ports will be forwarded (31100-31120)

Create cluster deploy file and deploy:
```bash
export PROXY_REGISTRY_PATH=/mnt/sdcard/k8s-data/registry-data/docker-io-registry/
export POD_DATA_PATH=/mnt/sdcard/k8s-data/pod-data/
envsubst < k3d-template.yaml > k3d-deploy.yaml
k3d cluster create ivy-k3d-cluster --config k3d-deploy.yaml

```

Notes:
- Make sure the mount paths(k3s-data) is properly set and initialized
  - Currently its using a SDCard partioned as BTRFS volm
<!-- - Modify k3d-resolv.conf accordingly, using which k3d will add DNS nameserver entries to the cluster -->
- Make sure to add the k3d-network to ufw firewall
```bash
sudo ufw-docker install
```
### Basic Structure of Homebox

- Applications (e.g. Homebox) which doesn't require a HW, runs on Kubernetes
- Appliatsions which rquires HW (usb) that runs on Docker Compose/Docker

#### Kubernetes cluster brief

- Uses k3d to create a single node cluster
- Runs Traefik as Load Balancer
- Each program will use its own hostname matching
  - **Note**, hostname DNS is currently mananged by Home Gargoyle Router
  -  The application specific DNSs are wildcard, e.g. homebox.chromebox.lan translates to *.chromebox.lan
  - Added this line to `dnsmasq.conf`: `address=/chromebox.lan/10.110.210.248`
