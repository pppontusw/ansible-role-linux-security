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

3. Copy, chmod +x and run the the script called partition.sh (in the files folder) which will partition the disk and migrate /tmp /var /var/log /var/log/audit and /home to new partitions

4. Reboot


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

