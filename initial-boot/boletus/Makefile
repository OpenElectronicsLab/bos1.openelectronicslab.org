BUILDDIR=build

TARGET_ISO=$(BUILDDIR)/autoinstall.iso
TFTP_COMPLETE_TAG=$(BUILDDIR)/tftp/autoinstall.txt
AUTHORIZED_KEY_FILES= ../../secrets/ssh-keys/ace.keys \
					  ../../secrets/ssh-keys/eric.keys \
					  ../../secrets/ssh-keys/kms15.keys

all: $(TARGET_ISO) $(TFTP_COMPLETE_TAG)

clean:
	rm -rf $(BUILDDIR)

#########################################################
# ISO target
#########################################################
DEBIAN_ISO_URL=https://cdimage.debian.org/mirror/cdimage/archive/10.3.0/amd64/iso-cd/debian-10.3.0-amd64-netinst.iso
ISO_EXTRACTED_TAG=$(BUILDDIR)/iso/README.txt
INITRD_ISO_TAG=$(BUILDDIR)/initrd.iso/init

# create target
$(BUILDDIR)/.gitignore :
	mkdir -pv $(BUILDDIR)
	echo '*' > $@

# download the base install image
$(BUILDDIR)/debian_original.iso : $(BUILDDIR)/.gitignore
	wget $(DEBIAN_ISO_URL) -O $@
	touch $@

# extract the contents of the image
$(ISO_EXTRACTED_TAG) : $(BUILDDIR)/debian_original.iso
	mkdir -pv $(BUILDDIR)/iso
	cd $(BUILDDIR)/iso && 7z x ../debian_original.iso
	touch $@

# update the grub.cfg to include a menu option for a preseeded install
# (Used for UEFI)
$(BUILDDIR)/iso/boot/grub/grub.cfg : grub.cfg $(ISO_EXTRACTED_TAG)
	cp $< $@

# update the isolinux.cfg to do a preseeded install
# (Used for Legacy BIOS)
$(BUILDDIR)/iso/isolinux/isolinux.cfg : isolinux.cfg $(ISO_EXTRACTED_TAG)
	cp $< $@

# extract the initrd.gz file (part of the iso image)
$(BUILDDIR)/iso/install.amd/initrd.gz : $(ISO_EXTRACTED_TAG)

# extract the contents of the initrd.gz file to the initrd.iso directory
$(INITRD_ISO_TAG) : $(BUILDDIR)/iso/install.amd/initrd.gz
	mkdir -pv $(BUILDDIR)/initrd.iso
	cd $(BUILDDIR)/initrd.iso \
		&& gzip -d < ../iso/install.amd/initrd.gz \
		| fakeroot cpio -id
	touch $@

# copy the preseed file into the initrd.iso tree
$(BUILDDIR)/initrd.iso/preseed.cfg : autoinstall-preseed.m4 $(INITRD_ISO_TAG)
	m4 -P $< > $@

# generate an authorized_keys file
$(BUILDDIR)/initrd.iso/authorized_keys : $(INITRD_ISO_TAG) \
		$(AUTHORIZED_KEY_FILES)
	cat $(AUTHORIZED_KEY_FILES) > $@

# recompress the initrd.iso directory to create a new initrd with the preseed
$(BUILDDIR)/iso/install.amd/preseedinitrd.gz : \
		$(BUILDDIR)/initrd.iso/preseed.cfg \
		$(BUILDDIR)/initrd.iso/authorized_keys \
		$(ISO_EXTRACTED_TAG)
	cd $(BUILDDIR)/initrd.iso \
		&& find . | fakeroot cpio -o -H newc \
		| gzip > ../iso/install.amd/preseedinitrd.gz

# generate the new iso install image
$(TARGET_ISO) : $(BUILDDIR)/iso/boot/grub/grub.cfg \
		$(BUILDDIR)/iso/isolinux/isolinux.cfg \
		$(BUILDDIR)/iso/install.amd/preseedinitrd.gz
	genisoimage -o $(BUILDDIR)/temp.iso \
		-b isolinux/isolinux.bin -c isolinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table -J -R \
		-V "Automated debian installer" $(BUILDDIR)/iso
	isohybrid $(BUILDDIR)/temp.iso # make USB-bootable
	mv $(BUILDDIR)/temp.iso $@

# Boot a qemu virtual machine using the new iso install file to test it
# Command-line notes: 512 MiB RAM, 1 CPU, KVM acceleration, forward
# localhost:10022 to guest port 22 (ssh) and localhost:10023 to guest port 23
# (dropbear ssh)
#
# Note that you can unlock the VM in an automated fashion as follows:
# printf "temp" | ssh root@localhost -p 10023 -i id_installer_rsa
#
qemu-test : $(TARGET_ISO)
	qemu-img create -f qcow2 $(BUILDDIR)/iso-test.qcow2 16G
	qemu-system-x86_64 -hdb $(BUILDDIR)/iso-test.qcow2 \
		-cdrom $(TARGET_ISO) -m 4G -smp 2 -accel kvm \
		-nic user\
,hostfwd=tcp:127.0.0.1:10022-:22\
,hostfwd=tcp:127.0.0.1:10023-:23 \
		-curses # -boot d

#########################################################
# PXE (network boot) target
#########################################################
DEBIAN_NETBOOT_URL=https://cdimage.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz
TFTP_TAG=$(BUILDDIR)/tftp/version.info
INITRD_PXE_TAG=$(BUILDDIR)/initrd.pxe/init

# download the base netboot image
$(BUILDDIR)/netboot.tar.gz : $(BUILDDIR)/.gitignore
	wget $(DEBIAN_NETBOOT_URL) -O $@
	touch $@

# extract the netboot image
$(TFTP_TAG) : $(BUILDDIR)/netboot.tar.gz grub.cfg
	mkdir -pv $(BUILDDIR)/tftp
	cd $(BUILDDIR)/tftp && tar -xzf ../netboot.tar.gz
	ln -svf debian-installer/amd64/grubx64.efi \
		$(BUILDDIR)/tftp/grubx64.efi
	ln -svf debian-installer/amd64/bootnetx64.efi \
		$(BUILDDIR)/tftp/pxelinux.efi
	cp grub.cfg $(BUILDDIR)/tftp/debian-installer/amd64/grub/grub.cfg
	touch $@

# extract the initrd.gz file (part of the netboot image)
$(BUILDDIR)/tftp/debian-installer/amd64/initrd.gz : $(TFTP_TAG)

# extract the contents of the initrd.gz file to the initrd.pxe directory
$(INITRD_PXE_TAG) : $(BUILDDIR)/tftp/debian-installer/amd64/initrd.gz
	mkdir -pv $(BUILDDIR)/initrd.pxe
	cd $(BUILDDIR)/initrd.pxe \
		&& gzip -d < ../tftp/debian-installer/amd64/initrd.gz \
		| fakeroot cpio -id
	touch $@

# copy the preseed file into the initrd.pxe tree
$(BUILDDIR)/initrd.pxe/preseed.cfg : autoinstall-preseed.m4 \
		$(INITRD_PXE_TAG)
	m4 -P $< > $@

# generate an authorized_keys file
$(BUILDDIR)/initrd.pxe/authorized_keys : $(INITRD_PXE_TAG) \
	$(AUTHORIZED_KEY_FILES)
	cat $(AUTHORIZED_KEY_FILES) > $@

# create a pxelinux.cfg to boot using the preseed file
$(BUILDDIR)/tftp/pxelinux.cfg/default: pxelinux.cfg.autoinstall $(TFTP_TAG)
	cp $< $@
	sed -i -e "s#DRIVE#default#g" $@

# recompress the initrd.pxe directory to create a new initrd with the preseed
$(BUILDDIR)/tftp/debian-installer/amd64/initrd0.gz : \
		$(BUILDDIR)/initrd.pxe/preseed.cfg \
		$(BUILDDIR)/initrd.pxe/authorized_keys \
		$(TFTP_TAG)
	cd $(BUILDDIR)/initrd.pxe \
		&& find . \
		| fakeroot cpio -o -H newc \
		| gzip > ../tftp/debian-installer/amd64/initrd0.gz

$(TFTP_COMPLETE_TAG) : $(BUILDDIR)/tftp/debian-installer/amd64/initrd0.gz \
	$(BUILDDIR)/tftp/pxelinux.cfg/default
	echo "Configured for autoinstall on $$(date)" > $@

# Boot a qemu virtual machine using the new network boot files to test them
# Command-line notes: 512 MiB RAM, 1 CPU, KVM acceleration, forward
# localhost:10024 to guest port 22 (ssh) and localhost:10025 to guest port 23
# (dropbear ssh)
#
# Note that you can unlock the VM in an automated fashion as follows:
# printf "temp" | ssh root@localhost -p 10025 -i id_installer_rsa
#
qemu-pxe-test : $(TFTP_COMPLETE_TAG)
	qemu-img create -f qcow2 $(BUILDDIR)/pxe.qcow2 16G
	qemu-system-x86_64 -hda $(BUILDDIR)/pxe.qcow2 \
		-m 512M -smp 1 -accel kvm -boot cn \
		-nic user\
,hostfwd=tcp:127.0.0.1:10024-:22\
,hostfwd=tcp:127.0.0.1:10025-:23\
,tftp=$(BUILDDIR)/tftp\
,bootfile=/pxelinux.0 \
		-curses

