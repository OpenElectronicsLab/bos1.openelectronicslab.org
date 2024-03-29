BUILDDIR=$(PWD)/build
CONFIGDIR=$(PWD)/config
DOWNLOADDIR=$(PWD)/download
SSHKEYSDIR=../../../secrets/ssh-keys
MACHINENAME=ihavenoname
INITRD=$(MACHINENAME)_initrd.gz

TARGET_ISO=$(BUILDDIR)/autoinstall.iso
TFTP_COMPLETE_TAG=$(BUILDDIR)/tftp/autoinstall.txt
AUTHORIZED_KEY_FILES= $(SSHKEYSDIR)/ace.keys \
					  $(SSHKEYSDIR)/eric.keys \
					  $(SSHKEYSDIR)/kms15.keys

all: $(TARGET_ISO) $(TFTP_COMPLETE_TAG)

clean:
	rm -rf $(BUILDDIR)

downloads: $(DOWNLOADDIR)/debian_original.iso \
	$(DOWNLOADDIR)/netboot.tar.gz

# create build directory
$(BUILDDIR)/.gitignore :
	mkdir -pv $(BUILDDIR)
	echo '*' > $@

# create download directory
$(DOWNLOADDIR)/.gitignore :
	mkdir -pv $(DOWNLOADDIR)
	echo '*' > $@

#########################################################
# ISO target
#########################################################
DEBIAN_ISO_URL=https://cdimage.debian.org/mirror/cdimage/archive/11.3.0/amd64/iso-cd/debian-11.3.0-amd64-netinst.iso
ISO_EXTRACTED_TAG=$(BUILDDIR)/iso/README.txt
INITRD_ISO_TAG=$(BUILDDIR)/initrd.iso/init

# download the base install image
$(DOWNLOADDIR)/debian_original.iso : $(DOWNLOADDIR)/.gitignore
	wget $(DEBIAN_ISO_URL) -O $@
	touch $@

# extract the contents of the image
$(ISO_EXTRACTED_TAG) : $(DOWNLOADDIR)/debian_original.iso $(BUILDDIR)/.gitignore
	mkdir -pv $(BUILDDIR)/iso
	cd $(BUILDDIR)/iso && 7z -y x $(DOWNLOADDIR)/debian_original.iso
	touch $@

# update the grub.cfg to include a menu option for a preseeded install
# (Used for UEFI)
$(BUILDDIR)/iso/boot/grub/grub.cfg : grub.cfg $(ISO_EXTRACTED_TAG)
	cp $< $@
	sed -i -e 's/INITRD/$(INITRD)/g' $@

# update the isolinux.cfg to do a preseeded install
# (Used for Legacy BIOS)
$(BUILDDIR)/iso/isolinux/isolinux.cfg : isolinux.cfg $(ISO_EXTRACTED_TAG)
	cp $< $@
	sed -i -e 's/INITRD/$(INITRD)/g' $@

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
$(BUILDDIR)/initrd.iso/preseed.cfg : $(CONFIGDIR)/preseed.cfg \
		$(INITRD_ISO_TAG)
	cp $< $@

# generate an authorized_keys file
$(BUILDDIR)/initrd.iso/authorized_keys : $(INITRD_ISO_TAG) \
		$(AUTHORIZED_KEY_FILES)
	cat $(AUTHORIZED_KEY_FILES) > $@

# recompress the initrd.iso directory to create a new initrd with the preseed
$(BUILDDIR)/iso/install.amd/$(INITRD) : \
		$(BUILDDIR)/initrd.iso/preseed.cfg \
		$(BUILDDIR)/initrd.iso/authorized_keys \
		$(ISO_EXTRACTED_TAG)
	rm -rf $(BUILDDIR)/initrd.iso.tmp
	cp -r $(BUILDDIR)/initrd.iso $(BUILDDIR)/initrd.iso.tmp
	# set date to unix epoch for reproducible builds
	find $(BUILDDIR)/initrd.iso.tmp -exec touch --no-dereference \
		--date="@0" \{\} \;
	# gzip --no-name prevents adding the timestamp (for reproducibility)
	cd $(BUILDDIR)/initrd.iso.tmp \
		&& find . | LC_ALL=C sort \
		| fakeroot cpio -o -H newc --reproducible \
		| gzip --no-name > ../iso/install.amd/$(INITRD)

# generate the new iso install image
$(TARGET_ISO) : $(BUILDDIR)/iso/boot/grub/grub.cfg \
		$(BUILDDIR)/iso/isolinux/isolinux.cfg \
		$(BUILDDIR)/iso/install.amd/$(INITRD)
	SOURCE_DATE_EPOCH=0 xorrisofs -o $(BUILDDIR)/temp.iso \
		-b isolinux/isolinux.bin -c isolinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table -J -R \
		--set_all_file_dates 2020010203040506 \
		-V "debAutoInstall" $(BUILDDIR)/iso
	isohybrid --id 1 $(BUILDDIR)/temp.iso # make USB-bootable
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
$(DOWNLOADDIR)/netboot.tar.gz : $(DOWNLOADDIR)/.gitignore
	wget $(DEBIAN_NETBOOT_URL) -O $@
	touch $@

# extract the netboot image
$(TFTP_TAG) : $(DOWNLOADDIR)/netboot.tar.gz grub.cfg $(BUILDDIR)/.gitignore
	mkdir -pv $(BUILDDIR)/tftp
	cd $(BUILDDIR)/tftp && tar -xzf $(DOWNLOADDIR)/netboot.tar.gz
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
$(BUILDDIR)/initrd.pxe/preseed.cfg : $(CONFIGDIR)/preseed.cfg \
		$(INITRD_PXE_TAG)
	cp $< $@

# generate an authorized_keys file
$(BUILDDIR)/initrd.pxe/authorized_keys : $(INITRD_PXE_TAG) \
	$(AUTHORIZED_KEY_FILES)
	cat $(AUTHORIZED_KEY_FILES) > $@

# create a pxelinux.cfg to boot using the preseed file
$(BUILDDIR)/tftp/pxelinux.cfg/$(MACHINENAME): pxelinux.cfg.autoinstall $(TFTP_TAG)
	cp $< $@
	sed -i -e 's/INITRD/$(INITRD)/g' $@

# recompress the initrd.pxe directory to create a new initrd with the preseed
$(BUILDDIR)/tftp/debian-installer/amd64/$(INITRD) : \
		$(BUILDDIR)/initrd.pxe/preseed.cfg \
		$(BUILDDIR)/initrd.pxe/authorized_keys \
		$(TFTP_TAG)
	rm -rf $(BUILDDIR)/initrd.pxe.tmp
	cp -r $(BUILDDIR)/initrd.pxe $(BUILDDIR)/initrd.pxe.tmp
	find $(BUILDDIR)/initrd.pxe.tmp -exec touch --no-dereference --date="@0" \{\} \;
	cd $(BUILDDIR)/initrd.pxe.tmp \
		&& find . | LC_ALL=C sort \
		| fakeroot cpio -o -H newc --reproducible \
		| gzip -n > ../tftp/debian-installer/amd64/$(INITRD)

$(TFTP_COMPLETE_TAG) : $(BUILDDIR)/tftp/debian-installer/amd64/$(INITRD) \
	$(BUILDDIR)/tftp/pxelinux.cfg/$(MACHINENAME)
	echo "Configured for autoinstall" > $@

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

