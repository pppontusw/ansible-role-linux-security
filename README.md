Linux Security
=========

This role will: 

1. Install and configure AutoUpdate

2. Install and enable Fail2Ban

3. Set User/Group Owner on bootloader config

4. Restrict Core Dumps - using sysctl

5.  Disable SSH X11 Forwarding
  
6. Set SSH MaxAuthTries to 4 

And some Nixu audit stuff


### IMPORTANT
IF PARTITIONING IS SET TO ON YOU NEED TO FIRST CREATE THE PARTITIONS:

1. Expand the disk with 20GB

2. Log in to the server and switch to root ```sudo su root```

3. Create the below partitions using ```cfdisk /dev/xvda```

```
/dev/xvda2 3G primary
/dev/xvda3 5G primary
/dev/xvda4 12G extended
/dev/xvda5 5G primary
/dev/xvda6 2G primary
/dev/xvda7 5G primary
```

4. Run ```partprobe /dev/xvda``` to reload the kernel partition table

5. Run the partition.sh script and then reboot

```
if grep "xvda2" /etc/fstab; then
	echo "xvda2 is already specified in /etc/fstab, please double check what is going on"
	exit 1
fi

# create the filesystems
for i in {2,3,5,6,7}; 
	do mkfs -t ext4 /dev/xvda$i; 
done

# create temporary mount points
for i in {2,3,5,6,7}; 
	do mkdir /mnt/xvda$i; 
done

# mount the new partitions in their temporary mount point
for i in {2,3,5,6,7}; 
	do mount /dev/xvda$i /mnt/xvda$i; 
done

# copy all the data to the new partitions
cp -apx /tmp/* /mnt/xvda2
cp -apx /var/* /mnt/xvda3
cp -apx /var/log/* /mnt/xvda5
if [-d /var/log/audit]; then
	cp -apx /var/log/audit/* /mnt/xvda6
	rm -rf /mnt/xvda5/audit
else
	touch /mnt/xvda6/nothing
fi
cp -apx /home/* /mnt/xvda7
rm -rf /mnt/xvda3/log

# move all the in-use files to /bak for safekeeping
mkdir /bak
for i in /tmp /var /home; 
	do mv $i /bak; 
done

# unmount the new partitions from their temporary mount points
for i in {2,3,5,6,7}; 
	do umount /dev/xvda$i; 
done

# create final mount points for the new partitions
for i in /tmp /var /home; 
	do mkdir $i; 
done

# mount all the new partitions in the correct target location
mount /dev/xvda2 /tmp
mount /dev/xvda3 /var
mkdir /var/log
mount /dev/xvda5 /var/log
mkdir /var/log/audit
mount /dev/xvda6 /var/log/audit
mount /dev/xvda7 /home

# put the configuration in fstab for persistence
echo "/dev/xvda2      /tmp    ext4    rw    0 0
/dev/xvda3      /var    ext4    rw   0 0
/dev/xvda5     /var/log    ext4    rw    0 0
/dev/xvda6     /var/log/audit    ext4    rw    0 0
/dev/xvda7     /home   ext4    rw    0 0" >> /etc/fstab

echo "You will now need to reboot the server in order for everything to work with your new partition structure, when the server boots and everything works you can safely delete /bak"
```



Variables
------------

```
---
# defaults file for ansible-role-linux-security/
epel_repo_url: "https://dl.fedoraproject.org/pub/epel/epel-release-latest-{{ ansible_distribution_major_version }}.noarch.rpm"
epel_repo_gpg_key_url: "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-{{ ansible_distribution_major_version }}"
security_autoupdate_enabled: true
```


Requirements
------------

Debian or RedHat based linux distro


Example Playbook
----------------

    - hosts: tag_Os_Ubuntu_16_04
      roles:
        - linux-security

