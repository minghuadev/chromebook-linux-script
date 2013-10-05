#!/bin/bash
#https://gist.github.com/carletes/4674386#file-ubuntu-kernel-for-acer-c7-sh

#fc19kbuild.sh from ubuntu-kernel-for-acer-c7.sh
#changes: do not install libc6:i386 libssl:i386 git-core
#changes: patch for kernel 3.8


set -x

#
# Grab verified boot utilities from ChromeOS.
#
mkdir /usr/share/vboot
mkdir /mnt/xternsd
mount -o ro /dev/sda3 /mnt/xternsd
cp /mnt/xternsd/usr/bin/vbutil_* /usr/bin
		#_firmware, _kernel, _key, _keyblock, _what_keys
###cp /mnt/xternsd/usr/bin/dump_kernel_config /usr/bin
rsync -avz /mnt/xternsd/usr/share/vboot/ /usr/share/vboot/
umount /mnt/xternsd

#
# On the Acer C7, ChromeOS is 32-bit, so the verified boot binaries need a
# few 32-bit shared libraries to run under ChrUbuntu, which is 64-bit.
#
###apt-get install libc6:i386 libssl1.0.0:i386

#
# Fetch ChromeOS kernel sources from the Git repo.
#
###apt-get install git-core
###cd /usr/src
###git clone  https://git.chromium.org/git/chromiumos/third_party/kernel.git
###cd kernel
###git checkout origin/chromeos-3.4
cd ~/
git clone https://git.chromium.org/git/chromiumos/third_party/kernel-next.git
cd kernel-next
git checkout origin/chromeos-3.8
cd ~/ ; mv kernel-next chromeos-kernel-3-8
 

#
# Configure the kernel
#
# First we patch ``base.config`` to set ``CONFIG_SECURITY_CHROMIUMOS``
# to ``n`` ...
cd ~/chromeos-kernel-3-8
mv ./chromeos/config/base.config ./chromeos/config/base.config.orig
sed -e \
  's/CONFIG_SECURITY_CHROMIUMOS=y/CONFIG_SECURITY_CHROMIUMOS=n/' \
  ./chromeos/config/base.config.orig > ./chromeos/config/base.config

###
### uname -m: i686
### config: chromeos/config/i386/chromeos-pinetrail-i386.flavour.config
###         chromeos/config/x86_64/chromeos-intel-pineview.flavour.config
###./chromeos/scripts/prepareconfig chromeos-intel-pineview
./chromeos/scripts/prepareconfig chromeos-pinetrail-i386


#
# ... and then we proceed as per Olaf's instructions
#
###yes "" | make oldconfig
##mkdir ../objs
##cp .config ../objs
##yes "" | make O=../objs oldconfig
##make O=../objs mrproper

yes "" | make oldconfig
make
mkdir ~/modules
INSTALL_MOD_PATH=~/modules make modules_install
cp arch/x86/boot/bzImage ~/modules


#
# Build the Ubuntu kernel packages
#
###apt-get install kernel-package
###make-kpkg kernel_image kernel_headers

#
# Backup current kernel and kernel modules
#
mkdir ~/backup
tstamp=$(date +%Y-%m-%d-%H%M)
dd if=/dev/sda6 of=~/backup/kernel-backup-$tstamp
cp -Rp /lib/modules/3.4.0 ~/backup/lib-modules-3.4.0-backup-$tstamp

#
# Install kernel image and modules from the Ubuntu kernel packages we
# just created.
#
###dpkg -i /usr/src/linux-*.deb

if [ ! -e /lib/libcrypto.so.1.0.0 ] ; then 
    cd /lib
    sudo ln -s libcrypto.so.1.0.1e libcrypto.so.1.0.0
fi

#
# Extract old kernel config
#
vbutil_kernel --verify /dev/sda6 --verbose | tail -1 > /config-$tstamp-orig.txt

#
# Add ``disablevmx=off`` to the command line, so that VMX is enabled (for VirtualBox & Co)
#
sed -e 's/$/ disablevmx=off/' \
  /config-$tstamp-orig.txt > /config-$tstamp.txt

#
# Wrap the new kernel with the verified block and with the new config.
#
#see http://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/custom-firmware

cd ~/modules
##echo blah > dummy.txt
vbutil_kernel --pack newkernel \
  --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
  --version 1 \
  --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
  --config=config-orig.txt \
  --vmlinuz bzImage \
  --arch x86
##not work: --arch i686
##no need:	  --bootloader dummy.txt \
###changed from: 3.4.0 ...x86_64

#
# Make sure the new kernel verifies OK.
#
vbutil_kernel --verify newkernel

#
# Copy the new kernel to the KERN-C partition.
#
##dd if=/newkernel of=/dev/sda6

