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
# Fetch ChromeOS kernel sources from the Git repo.
#
usesnapshot=1
if [ $usesnapshot -eq 0 ]; then
  # the original repo has 3180375 objects, and .git size 769M:
  (cd ~/ && git clone https://git.chromium.org/git/chromiumos/third_party/kernel-next.git)
  (cd ~/kernel-next && git checkout origin/chromeos-3.8)
  (cd ~/ && mv kernel-next chromeos-kernel-3-8)
else
  # or fetch a smaller snapshot of 40561 objects, .git size 121M, 39m at 50-90KiB/s :
  (cd ~/ && git clone https://github.com/minghuadev/chromeos-kernel-3-8-work.git)
  (cd ~/ && mv chromeos-kernel-3-8-work/chromeos-kernel-3-8 ./)
fi

#
# Configure the kernel
#
  # First we patch ``base.config`` to set ``CONFIG_SECURITY_CHROMIUMOS``
  # to ``n`` ...
  (cd ~/chromeos-kernel-3-8 && \
    mv ./chromeos/config/base.config ./chromeos/config/base.config.orig)

  (cd ~/chromeos-kernel-3-8 && \
    sed -e \
    's/CONFIG_SECURITY_CHROMIUMOS=y/CONFIG_SECURITY_CHROMIUMOS=n/' \
    ./chromeos/config/base.config.orig > ./chromeos/config/base.config)

  (cd ~/chromeos-kernel-3-8 && \
    ./chromeos/scripts/prepareconfig chromeos-pinetrail-i386)

  (cd ~/chromeos-kernel-3-8 && \
    sed -i -e \
    's/CONFIG_ERROR_ON_WARNING=y/CONFIG_ERROR_ON_WARNING=n/' .config)

exit 0

