#!/bin/bash
# history:
#    https://gist.github.com/carletes/4674386#file-ubuntu-kernel-for-acer-c7-sh
#    fc19kbuild.sh from ubuntu-kernel-for-acer-c7.sh
#        changes: do not install libc6:i386 libssl:i386 git-core
#        changes: patch for kernel 3.8
#    update-build-kernel.sh
#    update-step<n>-<word>.sh  --split into multiple steps

if ! ls /root > /dev/null ; then 
    echo "Error: backup kernel needs root permission."
    exit 1
fi

set -x

#
# Backup current kernel and kernel modules
#
mkdir /home/user/modules/backup
tstamp=$(date +%Y-%m-%d-%H%M)
dd if=/dev/sda6 of=/home/user/modules/backup/kernel-backup-$tstamp
cp -Rp /lib/modules/3.4.0 /home/user/modules/backup/lib-modules-3.4.0-backup-$tstamp

#
# Extract old kernel config
#
vbutil_kernel --verify /dev/sda6 --verbose | tail -1 > /home/user/modules/backup/config-$tstamp-orig.txt

#
# Add ``disablevmx=off`` to the command line, so that VMX is enabled (for VirtualBox & Co)
#
sed -e 's/$/ disablevmx=off/' \
  /home/user/modules/backup/config-$tstamp-orig.txt > /home/user/modules/backup/config-$tstamp.txt
cp /home/user/modules/backup/config-$tstamp.txt /home/user/modules/config-new.txt

#
# Wrap the new kernel with the verified block and with the new config.
#
#see http://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/custom-firmware

cd /home/user/modules
vbutil_kernel --pack newkernel \
  --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
  --version 1 \
  --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
  --config=config-new.txt \
  --vmlinuz bzImage \
  --arch x86

#
# Make sure the new kernel verifies OK.
#
vbutil_kernel --verify newkernel

#
# Copy the new kernel to the KERN-C partition.
#
#dd if=/newkernel of=/dev/sda6
echo to copy new kernel: "dd if=newkernel of=/dev/sda6"
echo to copy new modules: "cp -a lib/modules/3.8.11 /lib/modules/"

