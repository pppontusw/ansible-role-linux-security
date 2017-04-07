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

1. Expand the disk with like 20Gb

2. Create the partitions using ```sudo cfdisk```

For example:
```
/dev/xvda2 3G primary
/dev/xvda3 5G primary
/dev/xvda4 12G extended
/dev/xvda5 5G primary
/dev/xvda6 2G primary
/dev/xvda7 5G primary
```

3. Reboot 

4. Make filesystems on them  and repeat for all

```for i in {2,3,5,6,7}; do sudo mkfs -t ext4 /dev/xvda$i; done ```

5. Mount the new disks in a new location and then copy everything over there
```
for i in {2,3,5,6,7}; do sudo mkdir /mnt/xvda$i; done
for i in {2,3,5,6,7}; do sudo mount /dev/xvda$i /mnt/xvda$i; done
sudo cp -apx /tmp/* /mnt/xvda2
sudo cp -apx /var/* /mnt/xvda3
sudo cp -apx /var/log/* /mnt/xvda5
sudo cp -apx /var/log/audit/* /mnt/xvda6
sudo cp -apx /home/* /mnt/xvda7
sudo rm -rf /mnt/xvda3/log
sudo mkdir /bak
for i in /tmp /var /home; do sudo mv $i /bak; done
for i in /tmp /var /home; do sudo mkdir $i; done
sudo mkdir /var/log 
sudo mkdir /var/log/audit
```

Add the below to /etc/fstab and run ```sudo mount -a```
```
/dev/xvda2      /tmp    ext4    rw    0 0
/dev/xvda3      /var    ext4    rw   0 0
/dev/xvda5     /var/log    ext4    rw    0 0
/dev/xvda6     /var/log/audit    ext4    rw    0 0
/dev/xvda7     /home   ext4    rw    0 0
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

