# testing backups
* coprinus running k3s -- need to configure k3s to bind to open ports
  on only .195 (not step on git running on .196) and especially set traefik
  on ports other than 80 and 443
  see: https://rancher.com/docs/k3s/latest/en/networking/#traefik-ingress-controller

# testing notes
We would like to be able spin up virtual machines and have acceptance tests
before running things on the physical cluster.

# load-balancer notes
HAProxy doesn't handle UDP (useful for things like videoconferencing).

# things to investigate
- Helm 3
- Debian live PXE boot to copy a VM image to a physical partition
  https://www.reversengineered.com/2014/05/17/building-and-booting-debian-live-over-the-network/

