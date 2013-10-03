#!/bin/bash
#hd-repartition.sh
#derived from install-ubuntu-1204-9.sh of chrubuntu

cfg_skip_diskwork=0 #set to 0 to do the real work

if grep bash /proc/$$/exe > /dev/null ; then
    echo good running from bash
else
    echo
    echo Bad running from non-bash
    echo Please use bash to run this script.
    echo
    exit 1
fi

# fw_type will always be developer for Mario.
# Alex and ZGB need the developer BIOS installed though.
fw_type="`crossystem mainfw_type`"
if [ ! "$fw_type" = "developer" ]; then
    echo -e "\nYou're Chromebook is not running a developer BIOS!"
    echo -e "You need to run:"
    echo -e ""
    echo -e "sudo chromeos-firmwareupdate --mode=todev"
    echo -e ""
    echo -e "and then re-run this script."
    return
else
    echo -e "\nOh good. You're running a developer BIOS...\n"
fi

# hwid lets us know if this is a Mario (Cr-48), Alex (Samsung Series 5), 
# ZGB (Acer), etc
hwid="`crossystem hwid`"

echo -e "Chome OS model is: $hwid\n"

read -p "Press [Enter] to continue..."

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

  target_disk="`rootdev -d -s`"

  # Do partitioning (if we haven't already)
  state_begin="`cgpt show -i 1 -n -b -q ${target_disk}`"
  state_size="`cgpt show -i 1 -n -s -q ${target_disk}`"
  state_next=$(($state_begin + $state_size))

  ckern_begin="`cgpt show -i 6 -n -b -q ${target_disk}`"
  ckern_size="`cgpt show -i 6 -n -s -q ${target_disk}`"
  ckern_next=$(($ckern_begin + $ckern_size))

  croot_begin="`cgpt show -i 7 -n -b -q ${target_disk}`"
  croot_size="`cgpt show -i 7 -n -s -q ${target_disk}`"
  croot_next=$(($croot_begin + $croot_size))

  sectbl_begin="`cgpt show ${target_disk} | grep 'Sec GPT table' | xargs | cut -d' ' -f1`"

# If KERN-C and ROOT-C are one, we partition, 
# otherwise assume they're what they need to be...
if [ "$ckern_size" ==  "1" -a "$croot_size" == "1" ]; then
  total_size=$state_size
else
  if [ $state_next -ne $ckern_begin ]; then echo Failed matching partition 1 to 6; exit 1; fi
  if [ $ckern_next -ne $croot_begin ]; then echo Failed matching partition 6 to 7; exit 1; fi
  if [ $croot_next -ge $sectbl_begin ]; then echo Failed matching partition 7 to h; exit 1; fi
  total_size=$(($state_size + $ckern_size + $croot_size))
fi

  max_ubuntu_size=$(($total_size/1024/1024/2))
  rec_ubuntu_size=$(($max_ubuntu_size - 1))

while : ;  do
      echo -n "Enter the GB size to assign to Linux (5 to $max_ubuntu_size, "
      echo -n "recommend $rec_ubuntu_size): "
      read ubuntu_size
      if [ ! $ubuntu_size -ne 0 2>/dev/null ]; then
        echo -e "\n\nNumbers only please...\n\n"
        continue
      fi
      if [ "$ubuntu_size" = "" ]; then
        echo -e "\n\nNumbers please...\n\n"
        continue
      fi
      if [ $ubuntu_size -lt 5 -o $ubuntu_size -gt $max_ubuntu_size ]; then
        echo -e "\n\nThat number is out of range.\n\n"
        continue
      fi
      break
done

# We've got our size in GB for ROOT-C so do the math...

    #calculate sector size for rootc
    rootc_size=$(($ubuntu_size*1024*1024*2))

    #kernc is always 16mb
    kernc_size=32768

    #new stateful size with rootc and kernc subtracted from original
    stateful_size=$(($total_size - $rootc_size - $kernc_size))

    #start stateful at the same spot it currently starts at
    stateful_start=$state_begin
    stateful_end=$((stateful_start + $stateful_size -1))

    #start kernc at stateful start plus stateful size
    kernc_start=$(($stateful_start + $stateful_size))
    kernc_end=$(($kernc_start + $kernc_size -1))

    #start rootc at kernc start plus kernc size
    rootc_start=$(($kernc_start + $kernc_size))
    rootc_end=$(($rootc_start + $rootc_size -1))

    #Do the real work
    
    echo -e "\n\nModifying partition table to make room for Linux." 
    echo -e "Your Chromebook will reboot, wipe your data and then"
    echo -e "you may install Linux..."

    echo ""
    echo "Size computed..."
    echo " 1 $stateful_start $stateful_size STATE ${target_disk} --end ${stateful_end}"
    echo " 6 $kernc_start $kernc_size KERN-C ${target_disk} --end ${kernc_end}"
    echo " 7 $rootc_start $rootc_size ROOT-C ${target_disk} --end ${rootc_end}"
    echo "Sec GPT table at $sectbl_begin"
    echo ""

if [ $cfg_skip_diskwork -eq 0 ]; then 

    echo ""
    echo "Doing the real work in 5 seconds ..."
    echo ""
    sleep 5

    umount /mnt/stateful_partition
    
    # stateful first
    cgpt add -i 1 -b $stateful_start -s $stateful_size -l STATE ${target_disk}

    # now kernc
    cgpt add -i 6 -b $kernc_start -s $kernc_size -l KERN-C ${target_disk}

    # finally rootc
    cgpt add -i 7 -b $rootc_start -s $rootc_size -l ROOT-C ${target_disk}

    echo ""
    echo "Reboot in 5 seconds ..."
    echo ""
    sleep 5

    reboot
    exit 1
fi

