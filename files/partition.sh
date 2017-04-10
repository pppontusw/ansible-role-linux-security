#!/bin/bash
if [ $(/sbin/parted -lm | grep ext4 | wc -l) -gt 1 ]
then
	echo "Looks like your disk is already partitioned, exiting.."
	exit 1
else
	apt-get install bc -y
	IN=$(/sbin/parted -m /dev/xvda unit GB print)
	IFS=';' read -d '' -ra line <<< "$IN"
	IFS=':' read -d '' -ra disk <<< "${line[1]}"
	IFS=':' read -d '' -ra partition <<< "${line[-2]}"
	DISKSIZE="${disk[1]%??}"
	PARTITIONSIZE="${partition[2]%??}"
	if [ $(echo "$DISKSIZE == $PARTITIONSIZE" |bc) -eq 1 ];
	then
		echo "There is no space left on your disk, you need at least 20GB of space to create the new partitions";
		exit 1
	elif [ $(echo "$PARTITIONSIZE+20 <= $DISKSIZE" |bc) -eq 1 ];
	then
		# to create the partitions programatically (rather than manually)
		# we're going to simulate the manual input to fdisk
		# The sed script strips off all the comments so that we can
		# document what we're doing in-line with the actual commands
		# Note that a blank line (commented as "defualt" will send a empty
		# line terminated with a newline to take the fdisk default.
		sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/xvda
		  n # new partition to fill the first partition gap that's like 9MB
		  p # primary partition
		  2 # partition number 2
		    # default - start at beginning of disk
		    # fill size
		  n # new partition
		  p # primary partition
		  3 # partition number 3
		    # default - start immediately after root partition
		  +3G # size
		  n # new partition
		  e # extended partition
		  4 # partion number 4
		    # default, start immediately after preceding partition
		   	# fill size
		  n # new partition
		  5 # partion number 5
		    # default, start immediately after preceding partition
		  +5G # size
		  n # new partition
		  6 # partion number 6
		    # default, start immediately after preceding partition
		  +5G # size
		  n # new partition
		  7 # partion number 7
		    # default, start immediately after preceding partition
		  +2G # size
		  n # new partition
		  8 # partion number 8
		    # default, start immediately after preceding partition
		   # fill the rest of the disk
		  p # print the in-memory partition table
		  w # write the partition table
		  q # and we're done
EOF
	else
		echo "You have less than 20GB of free space left, please add some more space to the disk"
		exit 1
	fi
fi

partprobe /dev/xvda

if grep "xvda" /etc/fstab
then
	echo "xvda is already specified in /etc/fstab, please double check what is going on"
	exit 1
fi

# create the filesystems
for i in {3,5,6,7,8}
do
	mkfs -t ext4 /dev/xvda$i
done

# create temporary mount points
for i in {3,5,6,7,8}
do
	mkdir /mnt/xvda$i
done

# mount the new partitions in their temporary mount point
for i in {3,5,6,7,8}
do
	mount /dev/xvda$i /mnt/xvda$i
done

# copy all the data to the new partitions
cp -apx /tmp/* /mnt/xvda3
cp -apx /var/* /mnt/xvda5
cp -apx /var/log/* /mnt/xvda6
if [ -d "/var/log/audit" ]
then
	cp -apx /var/log/audit/* /mnt/xvda7
	rm -rf /mnt/xvda6/audit
else
	touch /mnt/xvda7/nothing
fi
cp -apx /home/* /mnt/xvda8
rm -rf /mnt/xvda5/log

# move all the in-use files to /bak for safekeeping
mkdir /bak
for i in /tmp /var /home
do
	mv $i /bak
done

# unmount the new partitions from their temporary mount points
for i in {3,5,6,7,8}
do
	umount /dev/xvda$i
done

# create final mount points for the new partitions
for i in /tmp /var /home
do
	mkdir $i
done

# mount all the new partitions in the correct target location
mount /dev/xvda3 /tmp
mount /dev/xvda5 /var
mkdir /var/log
mount /dev/xvda6 /var/log
mkdir /var/log/audit
mount /dev/xvda7 /var/log/audit
mount /dev/xvda8 /home

rm /var/log/audit/nothing

# put the configuration in fstab for persistence
echo "/dev/xvda3      /tmp    ext4    rw    0 0
/dev/xvda5      /var    ext4    rw   0 0
/dev/xvda6     /var/log    ext4    rw    0 0
/dev/xvda7     /var/log/audit    ext4    rw    0 0
/dev/xvda8     /home   ext4    rw    0 0" >> /etc/fstab

echo "You will now need to reboot the server in order for everything to work with your new partition structure, when the server boots and everything works you can safely delete /bak"