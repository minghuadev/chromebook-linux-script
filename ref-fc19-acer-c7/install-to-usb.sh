#!/bin/bash
#make sure it runs from bash on chronos 

# fw_type will always be developer for Mario.
# Alex and ZGB need the developer BIOS installed though.

#install-to-usb.sh derived from install-ubuntu-1204-9.sh
#to be run on an acer c7 installing from a usb stick.

cfg_install_to=/dev/mmcblk0
cfg_install_from=/dev/sdb1
cfg_target_dir=/home/chronos/user

debug_skip_copy=1    #1 skip copy from usb to /mnt/stateful_partition/fc19acerc7
debug_skip_mkfs=0    #1 skip writing rootfs partition from files
debug_skip_rootfs=0  #1 skip writing rootfs partition from files
debug_skip_modules=0 #1 skip extracting module files
debug_mmc_usbboot=1  #mmc cannot boot. 1 to boot off a usb reader
debug_show_mkfs=0    #1 skip showing mkfs result

project_name=fc19acerc7
rootfsfile=fc19lxde.tgz
#rootfsfile=fc19minimal.tgz

#command line: have to choose usb or mmc
case "$1" in
"mmc"|"sd")
    cfg_install_to=/dev/mmcblk0 ;;
"usb")
    cfg_install_to=/dev/sdb ;;
*)
    echo "ERROR: must have mmc or usb on command line for a target"
    echo "       unknown target device"
    exit 1
esac

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

# copy files from usb to the repo on stateful partition
target_repo=$cfg_target_dir/$project_name
if [ ! -d $target_repo ]; then
    mkdir $target_repo
fi

cd $target_repo

if [ $debug_skip_copy -eq 0 ]; then
    # try mounting a USB / SD Card if it's there...
    if [ ! -d /tmp/usb_files ]; then
        mkdir /tmp/usb_files
    fi

    umount /dev/sdb1                > /dev/null 2>&1
    mount  /dev/sdb1 /tmp/usb_files > /dev/null 2>&1

    if [ ! -d /tmp/usb_files/$project_name ]; then 
        echo "ERROR: no fc19 dir on usb drive /dev/sdb1"
        exit 1
    fi

    # Copy /tmp/usb_files/$project_name/* to stateful partition
    if [ -d /tmp/usb_files/$project_name ]; then
        if [ ! -f $target_repo/$rootfsfile ]; then
            echo "Copying all $project_name/* files to $target_repo/"
            cp -rf /tmp/usb_files/$project_name/* $target_repo/
        else 
            echo "Using $project_name/* files in stateful partition..."
        fi
    else
        echo "ERROR: no $project_name dir on usb drive /dev/sdb1"
        exit 1
    fi
    umount /dev/sdb1                > /dev/null 2>&1
    umount /dev/sdb                 > /dev/null 2>&1
else
    if [ ! -f $rootfsfile ]; then 
        echo "ERROR: no $rootfsfile file in the target repo"
        exit 1
    fi
fi


if [ "$cfg_install_to" == "" ]; then
    target_disk="`rootdev -d -s`"
    echo "ERROR: not allowed to install to $target_disk"
    exit
fi
    target_disk=$cfg_install_to
    echo ""
    echo "Got  ${target_disk}  as the target device"
    echo ""
    echo "  WARNING! All data on this device will be wiped out!"
    echo "  WARNING! Continue at your own risk!"
    echo "  WARNING! Or hit  CTRL+C  now to quit!"
    echo ""
    read -p "  Press [Enter] to install fc19 on ${target_disk} ..."

echo ""
installstarttime=`date`
date
    echo "Creating cgpt partitions"
    ext_size="`blockdev --getsz ${target_disk}`"
    aroot_size=$((ext_size - 65600 - 33))
    parted --script ${target_disk} "mktable gpt"
    cgpt create ${target_disk} 
    cgpt add -i 6 -b 64 -s 32768 -S 1 -P 5 -l KERN-A -t "kernel" ${target_disk}
    cgpt add -i 7 -b 65600 -s $aroot_size -l ROOT-A -t "rootfs" ${target_disk}
    if [ $? -ne 0 ]; then
        echo "ERROR: cgpt command failed on $target_disk"
        exit 1
    fi
    sync
    blockdev --rereadpt ${target_disk}
    partprobe ${target_disk}
    crossystem dev_boot_usb=1

if [[ "${target_disk}" =~ "mmcblk" ]]; then
    target_rootfs="${target_disk}p7"
    target_kern="${target_disk}p6"
    if grep mmcblk /proc/mounts ; then
        echo "ERROR: mmcblk mounted"
        exit 1
    fi
elif [[ "${target_disk}" =~ "sdb" ]]; then
    target_rootfs="${target_disk}7"
    target_kern="${target_disk}6"
    if grep sdb /proc/mounts ; then
        echo "ERROR: usb (sdb) mounted"
        exit 1
    fi
else
    echo "ERROR: not allowed to install to non-mmcblk or non-usb device"
    exit 1
fi

echo "    Target Kernel Partition: $target_kern"
echo "    Target Root FS:          ${target_rootfs}"

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
if [ $debug_mmc_usbboot -ne 0 ]; then
    echo -n "console=tty1 debug verbose root=/dev/sdb7 "    >  kernel-config
    echo    "rootwait rw lsm.module_locking=0"              >> kernel-config
fi

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
    echo "/dev/sdb7  /  ext4  defaults  0 0" > /tmp/urfs/etc/fstab
    echo "fedora 19 install source: "    > /tmp/urfs/root/note-install-source
    echo "    boot Fedora-19-i386-netinst.iso then use net path " \
                                         >> /tmp/urfs/root/note-install-source
    echo "    http://<site>.com/<path>/releases/19/Everything/i386/os/ " \
                                         >> /tmp/urfs/root/note-install-source

echo "Sync ..."
    sync

echo "Dismounting rootfs..."
umount /tmp/urfs

echo "Writing kernel  $uer_kernfs  to  $target_kern ..."
    dd if=$use_kernfs of=${target_kern} 2>/dev/null
    if [ $? -ne 0 ]; then 
        echo "ERROR: failed writing kernel to $target_kern"
        exit 1
    fi

#Set linux partition as top priority for next boot
echo "Setting cgpt for disk ${target_disk}..."
cgpt add -i 6 -P 5 -T 1 ${target_disk}

if [ $debug_mmc_usbboot -ne 0 ]; then
    echo "Acer C7 cannot boot off mmc. Use a USB card reader to boot mmc."
fi

installfinishtime=`date`
echo "  Installation started at  $installstarttime"
echo "  Installation finished at $installfinishtime"

# reboot
echo ""
echo "reboot now"
exit 0


echo ""
echo "Things to do with the minimal fedora 19: "

echo ""
echo "  Install pkgs: tar net-tools openssh-server system-config-firewall-tui"
echo "  Disable fw:   systemctl stop firewalld.service"
echo ""
echo "  Install lxde: yum install @lxde-desktop"
echo "  Set LXDE as default for LXDM: "
echo "      cd /etc/systemd/system; rm display-manager.service ;"
echo "      ln -s /usr/lib/systemd/system/lxdm.service display-manager.service"

echo ""
echo "  Install more packages for x: "
echo "      yum install xorg-x11-server-Xorg xterm xorg-x11-xinit xorg-x11-drv-evdev"
echo "    (If on a laptop where the touchpad works with synaptics, add xorg-x11-drv-synaptics)"
echo "  Install a window manager, e.g. yum install openbox. dbus-x11 too."

echo ""
echo "  Or get a new image from scratch to have a minimal Fedora with only LXDE:"
echo "    - use Netinstall image"
echo "    - chose minimal and customise now, then only 4 bundle of packages: "
echo "      LXDE and Window managers, and in base system Fonts and X Window System"

echo ""
echo "sleep 10"
sleep 10
echo ""
##reboot

exit 0

