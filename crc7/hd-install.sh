#!/bin/bash
#make sure it runs from bash on chronos 

# fw_type will always be developer for Mario.
# Alex and ZGB need the developer BIOS installed though.

#install-to-hd.sh 
#install-to-usb.sh derived from install-ubuntu-1204-9.sh
#to be run on an acer c7 installing from a usb stick to hd, 
#or from hd to usb stick, or from hd to hd.

cfg_install_to=/dev/sda

debug_skip_mkfs=0    #1 skip writing rootfs partition from files
debug_skip_rootfs=0  #1 skip writing rootfs partition from files
debug_skip_modules=0 #1 skip extracting module files
debug_show_mkfs=1    #1 skip showing mkfs result

rootfsfile=fc19lxde.tgz

    function waitforflush() {
      fincnt=0
      finstart=`date`
      while true
      do
          retv=`top -n1 -b | grep 'flush' | egrep -v 'S [ ]*0'`
          rets=`echo -n $retv`
          if [ "$retv" == "" ]; then 
            fincnt=$(($fincnt + 1))
            #echo "  " found S0 ... $fincnt
          else
            fincnt=0
          fi
          if [ $fincnt -gt 5 ]; then 
            echo "  " found S0 ... many times. idle. 
            break
          fi
          sleep 1
      done
      finfinish=`date`
      echo "  waitforflush started   $finstart"
      echo "  waitforflush finished  $finfinish"
    }

if grep bash /proc/$$/exe > /dev/null ; then
    echo good running from bash
else
    echo
    echo Bad running from non-bash
    echo Please use bash to run this script.
    echo
    exit 1
fi

echo ""
fw_type="`crossystem mainfw_type`"
if [ ! "$fw_type" = "developer" ]; then
    echo "Your Chromebook is not running a developer BIOS!"
    echo "  You need to run:"
    echo "     sudo chromeos-firmwareupdate --mode=todev"
    echo "  Then re-run this script."
    exit 1
else
    echo "You're running a developer BIOS. Good."
fi

# hwid lets us know if this is a Mario (Cr-48), Alex (Samsung Series 5), 
#                                               ZGB (Acer), etc
hwid="`crossystem hwid`"
    #PARROT PUFFIN F-D 0168

echo -e "Chomebook model is: $hwid\n"

chromebook_arch="`uname -m`"
if [ ! "$chromebook_arch" = "i686" ]; then
    echo -e "  This version of Chrome OS isn't i686."
    echo "ERROR: non-i686 kernel is not supported"
    exit 1
else
    echo -e "    and you're running a i686 version of Chrome OS! Good!\n"
fi

read -p "  Press [Enter] to continue..."

powerd_status="`initctl status powerd`"
if [ ! "$powerd_status" = "powerd stop/waiting" ]; then
    echo -e "Stopping powerd to keep display from timing out..."
    initctl stop powerd
fi

powerm_status="`initctl status powerm`"
if [ ! "$powerm_status" = "powerm stop/waiting" ]; then
    echo -e "Stopping powerm to keep display from timing out..."
    initctl stop powerm
fi

setterm -blank 0

    echo "Check data/$rootfsfile..."
    (cd data && sha1sum -c conf-fc19lxde-sha1)
    if [ $? -ne 0 ]; then
        echo "Error sah1sum check rootfs file data/$rootfsfile"
        echo "    Please try delete directory data and re-download data"
        exit 1
    fi
    cp data/$rootfsfile .
    if [ ! -f $rootfsfile ]; then 
        echo "ERROR: no $rootfsfile file"
        exit 1
    fi

if [ "$cfg_install_to" == "" ]; then
    target_disk="`rootdev -d -s`"
    echo "ERROR: not allowed to install to $target_disk"
    exit
fi

    target_disk=$cfg_install_to
    target_rootfs="${target_disk}7"
    target_kern="${target_disk}6"
echo "    Target Kernel Partition: $target_kern"
echo "    Target Root FS:          ${target_rootfs}"

    echo ""
    echo "Got  ${target_disk}  as the target device"
    echo ""
    echo "  WARNING! All data on the kernel or rootfs partitions will be wiped out!"
    echo "  WARNING! Continue at your own risk!"
    echo "  WARNING! Or hit  CTRL+C  now to quit!"
    echo ""
    read -p "  Press [Enter] to install fc19 on ${target_disk} ..."

echo ""
installstarttime=`date`
date

if grep $target_rootfs /proc/mounts ; then 
    echo "ERROR: $target_rootfs mounted"
    exit 1
fi

echo "Creating ext4 fs on ${target_rootfs}..."
if [ $debug_skip_mkfs -eq 0 ]; then 
    if [ $debug_show_mkfs -eq 0 ] ; then 
        mkfs -t ext4 ${target_rootfs}  > /dev/null
    else
        time mkfs -t ext4 ${target_rootfs}
    fi
fi

#Mount rootfs and copy cgpt + modules over
echo "Mounting ${target_rootfs}..."
if [ ! -d /tmp/urfs ]; then
    mkdir /tmp/urfs
fi
mount -t ext4 ${target_rootfs} /tmp/urfs
df -h /tmp/urfs

echo -n "Copying rootfs ... (may take 20 minutes or longer) ...  "
    date
    tar zxf $rootfsfile --directory /tmp/urfs
echo -n '  waitforflush ... (may take 20 minutes or longer) ...  '
    date
waitforflush

echo "Copying modules, firmware and binaries to ${target_rootfs}..."
if [ ! -d /tmp/urfs/usr/bin ]; then
    echo -e "\nError mounted target with no /usr/bin\n\n"
    exit 1
else
    echo "Mounted  ${target_rootfs}  at  /tmp/urfs ok"
    df -h /tmp/urfs
            #mario rootfs 5.0G total, 3.1G used, 1.7G availab.
fi

echo "Copying cgpt..."
cp /usr/bin/cgpt /tmp/urfs/usr/bin/
chmod a+rx /tmp/urfs/usr/bin/cgpt

echo -n "console=tty1 debug verbose root=${target_rootfs} " >  kernel-config
echo    "rootwait rw lsm.module_locking=0"                  >> kernel-config

echo "Checking kernel..."
    orig_root_part=`rootdev -s`
    if [ "$orig_root_part" == "/dev/sda5" ]; then
        orig_kern_part="/dev/sda4"
    elif [ "$orig_root_part" == "/dev/sda3" ]; then
        orig_kern_part="/dev/sda2"
    else
        echo "ERROR: unknown kernel partition  $orig_root_part"
        exit 1
    fi
  
    use_kernfs="kernel-partition"
    if [ -f $use_kernfs ]; then rm $use_kernfs; fi

echo "Using kernel from $orig_kern_part as ${use_kernfs}_oldblb ..."
    dd if=$orig_kern_part of=$use_kernfs  2>/dev/null
    if [ $? -ne 0 ]; then 
        echo "ERROR: failed extracting kernel from $orig_kern_part"
        exit 1
    fi

    mv $use_kernfs ${use_kernfs}_oldblb
    vbutil_kernel --repack $use_kernfs \
                --keyblock /usr/share/vboot/devkeys/kernel.keyblock \
                --version 1 \
                --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
                --config kernel-config \
                --oldblob ${use_kernfs}_oldblb > /dev/null
    if [ $? -ne 0 ]; then 
        echo "ERROR: failed repacking kernel"
        exit 1
    fi

echo "Copying modules to /lib/modules..."
    if [ $debug_skip_modules -eq 0 ]; then
        if [ ! -d /tmp/urfs/lib/modules ]; then
            echo "ERROR: no /lib/modules/ on target"
            exit 1
        fi
        cp -a /lib/modules/* /tmp/urfs/lib/modules/
    fi

echo "Modifying fstab..."
    mv /tmp/urfs/etc/fstab /tmp/urfs/etc/fstab-orig-inst
    echo "$target_rootfs  /  ext4  defaults  0 0" > /tmp/urfs/etc/fstab
    echo "fedora 19 install source: "    > /tmp/urfs/root/note-install-source
    echo "    boot Fedora-19-i386-netinst.iso then use net path " \
                                         >> /tmp/urfs/root/note-install-source
    echo "    http://<site>.com/<path>/releases/19/Everything/i386/os/ " \
                                         >> /tmp/urfs/root/note-install-source
    echo ""                              >> /tmp/urfs/root/note-install-source
    echo "Using kernel from partition $orig_kern_part" \
                                         >> /tmp/urfs/root/note-install-source

echo "Sync ..."
    sync

echo "Dismount rootfs ..."
umount /tmp/urfs

echo "Writing kernel  $uer_kernfs  to  $target_kern ..."
    dd if=$use_kernfs of=${target_kern} 2>/dev/null
    if [ $? -ne 0 ]; then 
        echo "ERROR: failed writing kernel to $target_kern"
        exit 1
    fi

#Set linux partition as top priority for next boot
echo "Setting cgpt for disk ${target_disk}..."
cgpt add -i 6 -P 5 -T 1 -S 1 ${target_disk}

installfinishtime=`date`
echo "  Installation started at  $installstarttime"
echo "  Installation finished at $installfinishtime"

# reboot
echo ""
echo "going to reboot"

echo ""
echo "Things to do with the minimal fedora 19 lxde environment: "

echo ""
echo "  Change root password. it is set to root temporary now."
echo "  Change user password. it is set to user temporary now."
echo ""
echo "  Install KDE with:          yum install kde-workspace "
echo "  Install touchpad package:  yum install kcm_touchpad  "
echo "  Install KDE network manager:    "
echo "                             yum install kde-plasma-networkmanagement  "

echo ""
echo "sleep 10"
sleep 10
echo ""
reboot

exit 0

