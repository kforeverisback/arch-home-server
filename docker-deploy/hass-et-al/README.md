# Deploy Home Assistant et al

- First create Mosquitto password file:
```bash
docker run -it --rm --entrypoint mosquitto_passwd -v /opt/mosquitto:/opt/mosquitto -u 1000:1000  eclipse-mosquitto:latest -c /opt/mosquitto/pwfile kushal
```
- For Mosquitto the log directory needs to be owned by 1883
sudo chown 1883:1883 /srv/mosquitto/log -R

## TODO
- https://www.smarthomebeginner.com/traefik-2-docker-tutorial/
