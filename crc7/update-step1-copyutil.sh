#!/bin/bash
# history:
#    https://gist.github.com/carletes/4674386#file-ubuntu-kernel-for-acer-c7-sh
#    fc19kbuild.sh from ubuntu-kernel-for-acer-c7.sh
#        changes: do not install libc6:i386 libssl:i386 git-core
#        changes: patch for kernel 3.8
#    update-build-kernel.sh
#    update-step<n>-<word>.sh  --split into multiple steps

if ! ls /root > /dev/null ; then 
    echo "Error: copying chromeos utils needs root permission."
    exit 1
fi

set -x


# Grab verified boot utilities from ChromeOS.

  mkdir /usr/share/vboot
  mkdir /mnt/xternsd
  mount -o ro /dev/sda3 /mnt/xternsd
  cp /mnt/xternsd/usr/bin/vbutil_* /usr/bin
		#_firmware, _kernel, _key, _keyblock, _what_keys
  cp /mnt/xternsd/usr/bin/dump_kernel_config /usr/bin
  rsync -avz /mnt/xternsd/usr/share/vboot/ /usr/share/vboot/
  umount /mnt/xternsd

if [ ! -e /lib/libcrypto.so.1.0.0 ] ; then 
  ( cd /lib && ln -s libcrypto.so.1.0.1e libcrypto.so.1.0.0 )
fi

exit 0

