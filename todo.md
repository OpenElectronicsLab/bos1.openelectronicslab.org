# TODO

## supporting physical machines
- morchella wireguard and kvm setup
- morchella DHCP server setup
- PXE boot setup
- boletus PXE boot
- boletus ansible setup
- static IP setup
- back-haul network setup
- boletus firewall/reverse proxy setup (keepalived + haproxy?)
- virtual machine hypervisor (kvm/virt-lib?)
- network storage setup (ceph?)

## virtual machine infrastructure
- clustering setup (kubernetes?)
- networking layer (calico?)
- microservice mesh (istio?)
- logging/metrics (Prometheus + Grafana?)

## services
- DNS (unbound?)
- email openelectronicslab.org
- email list management
- video conf (jit.si?) and voice (mumble?)
- mirrored/HA gitlab
- nextcloud
- file synching service (syncthing?)
- hosted xvnc dev env
- jupyter, tensorflow, gpu gpu hacking env

## migration
- move logicgate.nl into our infra
- create logicgate email
- transform venus into cloud node
- move tdf web content into our infra
- move tdf email into our infra
- spin-down tdf
- move kendrickshaw.org website

## improvements
- document how the "temp" passphrase can be exploited if there is physical
  access to the machines
- replace the "temp" passphrase with a secret
- switch from iptables to nftables syntax in ansible scripts
- add wireguard VPN accesses to management network etc.
