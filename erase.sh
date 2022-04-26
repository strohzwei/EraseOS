#!/bin/bash
PTUUID_TO_IGNORE="179627f6-2618-48ad-9521-b321692810e3"
DEVICES=($(ls /dev/disk/by-path/ | grep -v "\-part"))
OPTIONS=()
for i in "${!DEVICES[@]}"; do
  OPTIONS+=($i "${DEVICES[$i]}" on)
  echo "$i ${DEVICES[$i]}"
done
cmd=(dialog --timeout 10 --separate-output --checklist "Select options or wait 10s:" 22 76 16)
choices=$("${cmd[@]}" "${OPTIONS[@]}" 2>&1 >/dev/tty)
rc=$?
clear
case $rc in
	255) echo "Deleting all drives."; choices=$(seq 0 $(( ${#DEVICES[@]} -1 )));
esac
for choice in $choices
do
     DISK="/dev/disk/by-path/${DEVICES[$choice]}"
     blkid $DISK | grep $PTUUID_TO_IGNORE >/dev/null && echo "Skipping ${DEVICES[$choice]}." && continue
     echo -e "\nNext drive to erase \e[31m${DEVICES[$choice]}\e[0m."
     read -t 10 -p "Hit ENTER to cancel! Continue after 10s." && exit 1
     echo
     # https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
     # to create the partitions programatically (rather than manually)
     # we're going to simulate the manual input to fdisk
     # The sed script strips off all the comments so that we can 
     # document what we're doing in-line with the actual commands
     # Note that a blank line (commented as "defualt" will send a empty
     # line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $DISK
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default - entire disk
  J # remove signature Ja
  w # write the partition table
EOF
partprobe
mkfs.ext3 "$DISK-part1"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $DISK
  g # new table gpt
  w # write
  q # and we're done
EOF
partprobe
done

#for i in $(seq 0 10 100) ; do sleep 1; echo $i | dialog --gauge "Please wait" 10 70 0; done
