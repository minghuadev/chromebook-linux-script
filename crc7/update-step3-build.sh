#!/bin/bash
# history:
#    https://gist.github.com/carletes/4674386#file-ubuntu-kernel-for-acer-c7-sh
#    fc19kbuild.sh from ubuntu-kernel-for-acer-c7.sh
#        changes: do not install libc6:i386 libssl:i386 git-core
#        changes: patch for kernel 3.8
#    update-build-kernel.sh
#    update-step<n>-<word>.sh  --split into multiple steps

if ls /root > /dev/null 2>&1 ; then 
    echo "Error: checking out code does not root permission."
    exit 1
fi

set -x

#
# ... and then we proceed as per Olaf's instructions
#

  (cd ~/chromeos-kernel-3-8 && (yes "" | make oldconfig) )
  (cd ~/chromeos-kernel-3-8 &&  make)
  mkdir ~/modules
  (cd ~/chromeos-kernel-3-8 &&  (INSTALL_MOD_PATH=~/modules make modules_install))
  cp ~/chromeos-kernel-3-8/arch/x86/boot/bzImage ~/modules

exit 0

