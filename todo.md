# TODO

## before we ship to DC steps
- static IP ansible support
- infiniband switch basic test
- check all luks keys
- final check of hardware
- usb key check

## other
- debug git.openelectronicslab.org backup failure
- debug `pmi_kvm_docker` issue with the javaws console console redirect
  - consider: https://github.com/sunfoxcz/ipmiview
  - see also: https://github.com/ixs/kvm-cli
- reproducible ISO builds
- reproducible tftp builds
- set BIOS and IPMI passwords
- safety checks for commands like `reinstall_os_via_pxe`
- group vars hackiness around `pxe_mac` and `pxe_file` variables

## supporting physical machines
- morchella wireguard and kvm setup
- PXE boot setup
- boletus PXE boot
- boletus ansible setup
- static IP setup
- back-haul network setup
- boletus firewall/reverse proxy setup (keepalived + haproxy?)
- virtual machine hypervisor (kvm/virt-lib?)
- network storage setup (ceph?)
- encryption unlock to listen on multiple cards
- fix qemu pxeboot test for (machine name)

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
- move git.openelectronicslab.org into new infra
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
