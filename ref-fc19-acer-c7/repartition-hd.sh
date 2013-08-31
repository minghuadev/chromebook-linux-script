#!/bin/bash
#derived from install-ubuntu-1204-9.sh

cfg_skip_diskwork=0 #set to 0 to do the real work

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
  ckern_size="`cgpt show -i 6 -n -s -q ${target_disk}`"
  croot_size="`cgpt show -i 7 -n -s -q ${target_disk}`"
  state_size="`cgpt show -i 1 -n -s -q ${target_disk}`"

  max_ubuntu_size=$(($state_size/1024/1024/2))
  rec_ubuntu_size=$(($max_ubuntu_size - 2))

# If KERN-C and ROOT-C are one, we partition, 
# otherwise assume they're what they need to be...
if [ ! "$ckern_size" =  "1" -o ! "$croot_size" = "1" ]; then
    echo "Nothing to do as kernel size $ckern_size and root size $croot_size"
    exit 1
fi

while : ;  do
      read -p "Enter the size in gigabytes you want to reserve for Ubuntu. Acceptable range is 5 to $max_ubuntu_size  but $rec_ubuntu_size is the recommended maximum: " ubuntu_size
      if [ ! $ubuntu_size -ne 0 2>/dev/null ]; then
        echo -e "\n\nNumbers only please...\n\n"
        continue
      fi
      if [ "$ubuntu_size" = "" ]; then
        echo -e "\n\nNumbers please...\n\n"
        continue
      fi
      if [ $ubuntu_size -lt 5 -o $ubuntu_size -gt $max_ubuntu_size ]; then
        echo -e "\n\nThat number is out of range. Enter a number 5 through $max_ubuntu_size\n\n"
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
    stateful_size=$(($state_size - $rootc_size - $kernc_size))

    #start stateful at the same spot it currently starts at
    stateful_start="`cgpt show -i 1 -n -b -q ${target_disk}`"

    #start kernc at stateful start plus stateful size
    kernc_start=$(($stateful_start + $stateful_size))

    #start rootc at kernc start plus kernc size
    rootc_start=$(($kernc_start + $kernc_size))

    #Do the real work
    
    echo -e "\n\nModifying partition table to make room for Ubuntu." 
    echo -e "Your Chromebook will reboot, wipe your data and then"
    echo -e "you should re-run this script..."

    echo ""
    echo "Size computed..."
    echo " 1 $stateful_start $stateful_size STATE ${target_disk}"
    echo " 6 $kernc_start $kernc_size KERN-C ${target_disk}"
    echo " 7 $rootc_start $rootc_size ROOT-C ${target_disk}"
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

