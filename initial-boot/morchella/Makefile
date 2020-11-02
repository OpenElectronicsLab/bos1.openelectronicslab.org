TARGET_ISO=morchella0.iso
DEBIAN_ISO_URL=https://cdimage.debian.org/mirror/cdimage/archive/10.3.0/amd64/iso-cd/debian-10.3.0-amd64-netinst.iso
ISO_EXTRACTED_TAG=iso/README.txt
AUTHORIZED_KEY_FILES= ../../secrets/ssh-keys/ace.keys \
					  ../../secrets/ssh-keys/eric.keys \
					  ../../secrets/ssh-keys/kms15.keys

default: $(TARGET_ISO)

clean:
	rm -rf $(TARGET_ISO)
	rm -rf iso
	rm -rf test.qcow2

#########################################################
# ISO target
#########################################################

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
	qemu-img create -f qcow2 test.qcow2 16G
	qemu-system-x86_64 -hda test.qcow2 -cdrom $(TARGET_ISO) -m 4G -smp 2 -accel kvm \
		-nic user,hostfwd=tcp:127.0.0.1:10022-:22,hostfwd=tcp:127.0.0.1:10023-:23 \
		-curses # -boot d
