# testing notes
We would like to be able spin up virtual machines and have acceptance tests
before running things on the physical cluster.

# load-balancer notes
HAProxy doesn't handle UDP (useful for things like videoconferencing).

# things to investigate
- Helm 3
- Debian live PXE boot to copy a VM image to a physical partition
  https://www.reversengineered.com/2014/05/17/building-and-booting-debian-live-over-the-network/

