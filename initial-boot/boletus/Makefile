TARGET_ISO=morchella0.iso
TFTP_COMPLETE_TAG=tftp/autoinstall.txt
AUTHORIZED_KEY_FILES= ../../secrets/ssh-keys/ace.keys \
					  ../../secrets/ssh-keys/eric.keys \
					  ../../secrets/ssh-keys/kms15.keys

all: $(TARGET_ISO) $(TFTP_COMPLETE_TAG)

clean:
	rm -rf $(TARGET_ISO)
	rm -rf iso
	rm -rf iso-test.qcow2
	rm -rf tftp
	rm -rf initrd.pxe
	rm -rf pxe-test.qcow2

#########################################################
# ISO target
#########################################################
DEBIAN_ISO_URL=https://cdimage.debian.org/mirror/cdimage/archive/10.3.0/amd64/iso-cd/debian-10.3.0-amd64-netinst.iso
ISO_EXTRACTED_TAG=iso/README.txt

# download the base install image
debian_original.iso :
	wget $(DEBIAN_ISO_URL) -O $@

# extract the contents of the image
$(ISO_EXTRACTED_TAG) : debian_original.iso
	mkdir -p iso
	cd iso && 7z x ../$<
	touch $@

# copy the preseed file to the appropriate location (using m4 to expand macros)
iso/preseed/autoinstall-preseed.seed : autoinstall-preseed.m4 \
		$(ISO_EXTRACTED_TAG)
	mkdir -p iso/preseed
	m4 -P $< > $@

# update the grub.cfg to include a menu option for a preseeded install
# (Used for UEFI)
iso/boot/grub/grub.cfg : grub.cfg $(ISO_EXTRACTED_TAG)
	cp $< $@

# update the isolinux.cfg to do a preseeded install
# (Used for Legacy BIOS)
iso/isolinux/isolinux.cfg : isolinux.cfg $(ISO_EXTRACTED_TAG)
	cp $< $@

# generate an authorized_keys file
iso/preseed/authorized_keys : $(ISO_EXTRACTED_TAG) $(AUTHORIZED_KEY_FILES)
	cat $(AUTHORIZED_KEY_FILES) > $@

# generate the new iso install image
$(TARGET_ISO) : iso/preseed/autoinstall-preseed.seed iso/boot/grub/grub.cfg \
		iso/isolinux/isolinux.cfg iso/preseed/authorized_keys
	genisoimage -o temp.iso -b isolinux/isolinux.bin -c isolinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table -J -R \
		-V "morchella0 debian installer" iso
	isohybrid temp.iso # make USB-bootable
	mv temp.iso $@

# Boot a qemu virtual machine using the new iso install file to test it
# Command-line notes: 512 MiB RAM, 1 CPU, KVM acceleration, forward
# localhost:10022 to guest port 22 (ssh) and localhost:10023 to guest port 23
# (dropbear ssh)
#
# Note that you can unlock the VM in an automated fashion as follows:
# printf "temp" | ssh root@localhost -p 10023 -i id_installer_rsa
#
qemu-test : $(TARGET_ISO)
	qemu-img create -f qcow2 iso-test.qcow2 16G
	qemu-system-x86_64 -hda iso-test.qcow2 -cdrom $(TARGET_ISO) -m 4G -smp 2 -accel kvm \
		-nic user,hostfwd=tcp:127.0.0.1:10022-:22,hostfwd=tcp:127.0.0.1:10023-:23 \
		-curses # -boot d

#########################################################
# PXE (network boot) target
#########################################################
DEBIAN_NETBOOT_URL=https://cdimage.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz
TFTP_TAG=tftp/version.info
INITRD_PXE_TAG=initrd.pxe/init

# download the base netboot image
netboot.tar.gz :
	wget $(DEBIAN_NETBOOT_URL) -O $@
	touch $@

# extract the netboot image
$(TFTP_TAG) : netboot.tar.gz grub.cfg
	mkdir -p tftp
	cd tftp && tar -xzf ../netboot.tar.gz
	ln -sf debian-installer/amd64/grubx64.efi tftp/grubx64.efi
	ln -sf debian-installer/amd64/bootnetx64.efi tftp/pxelinux.efi
	cp grub.cfg tftp/debian-installer/amd64/grub/grub.cfg
	touch $@

# extract the initrd.gz file (part of the netboot image)
tftp/debian-installer/amd64/initrd.gz : $(TFTP_TAG)

# extract the contents of the initrd.gz file to the initrd.pxe directory
$(INITRD_PXE_TAG) : tftp/debian-installer/amd64/initrd.gz
	mkdir -p initrd.pxe
	cd initrd.pxe && gzip -d < ../$< | fakeroot cpio -id
	touch $@

# copy the preseed file into the initrd.pxe tree
initrd.pxe/preseed_default.cfg : autoinstall-preseed.m4 \
		$(INITRD_PXE_TAG)
	m4 -P $< > $@

# generate an authorized_keys file
initrd.pxe/authorized_keys : $(INITRD_PXE_TAG) $(AUTHORIZED_KEY_FILES)
	cat $(AUTHORIZED_KEY_FILES) > $@

# create a pxelinux.cfg to boot using the preseed file
tftp/pxelinux.cfg/preseeded_default: pxelinux.cfg.autoinstall $(TFTP_TAG)
	cp $< $@
	sed -i -e "s#DRIVE#default#g" $@

# recompress the initrd.pxe directory to create a new initrd with the preseed
tftp/debian-installer/amd64/initrd0.gz : \
		initrd.pxe/preseed_default.cfg \
		initrd.pxe/authorized_keys \
		$(TFTP_TAG)
	cd initrd.pxe && find . | fakeroot cpio -o -H newc | gzip > ../$@

$(TFTP_COMPLETE_TAG) : tftp/debian-installer/amd64/initrd0.gz \
	tftp/pxelinux.cfg/preseeded_default
	echo "Configured for autoinstall on $$(date)" > $@

# create a virtual hard disk image for a qemu virtual machine for testing
qemu-pxe-test-image.qcow2 : $(TFTP_COMPLETE_TAG)
	qemu-img create -f qcow2 $@ 8G

# Boot a qemu virtual machine using the new network boot files to test them
# Command-line notes: 512 MiB RAM, 1 CPU, KVM acceleration, forward
# localhost:10024 to guest port 22 (ssh) and localhost:10025 to guest port 23
# (dropbear ssh)
#
# Note that you can unlock the VM in an automated fashion as follows:
# printf "temp" | ssh root@localhost -p 10025 -i id_installer_rsa
#
qemu-pxe-test : qemu-pxe-test-image.qcow2 $(TFTP_COMPLETE_TAG)
	qemu-system-x86_64 -hda $< -m 512M -smp 1 -accel kvm -boot cn \
		-nic user,hostfwd=tcp:127.0.0.1:10024-:22,hostfwd=tcp:127.0.0.1:10025-:23,tftp=./tftp,bootfile=/pxelinux.0 \
		#-curses # -boot d

