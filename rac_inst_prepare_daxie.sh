#!/bin/sh
#node1:
#———————————————————————————————————
echo "alias bond0 bonding" > /etc/modprobe.d/bonding.conf
chkconfig --level 35 NetworkManager off
service NetworkManager stop

cp -r /etc/sysconfig/network-scripts/ /tmp 

echo "DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
IPADDR=10.1.1.67
NETMASK=255.255.255.0
GATEWAY=10.1.1.254
USERCTL=no
BONDING_OPTS="mode=1 miimon=100"
" > /etc/sysconfig/network-scripts/ifcfg-bond0

echo "DEVICE=bond1
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.178.1.67
NETMASK=255.255.255.0
GATEWAY=10.1.1.254
USERCTL=no
BONDING_OPTS="mode=1 miimon=100"
" > /etc/sysconfig/network-scripts/ifcfg-bond1



echo "DEVICE=em1
MASTER=bond0
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em1

echo "DEVICE=em2
MASTER=bond0
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em2

echo "DEVICE=em3
MASTER=bond1
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em3


echo "DEVICE=em4
MASTER=bond1
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em4

service network restart

#_________________________________________________________________________________________________________________________________________________________________________
cat /proc/net/bonding/bond0
cat /proc/net/bonding/bond1
#to manual confirm.
read -p "correct above and upload your software , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac

service iptables stop
chkconfig iptables off

echo  "
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
" > /etc/selinux/config

setenforce 0
sestatus
sleep 5

read -p "plugin your CD , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac

mount -o ro /dev/sr0 /media 

mount |grep media
#to manual confirm
read -p " mount succeed , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac
mv /etc/yum.repos.d/* /tmp
echo "
[InstallMedia]
name=Oracle Linux 6.5
gpgcheck=0
baseurl=file:///media 
" >> /etc/yum.repos.d/media.repo

yum repolist
yum -y install xorg-x11-xauth xterm Xserver xorg-x11-utils
yum install oracle-rdbms-server-11gR2-preinstall

#to set your multipath config
read -p "complete your multipath setting, yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac


 echo "
 # bond1 -changed rpf 
 net.ipv4.conf.bond1.rp_filter = 2
 " >> /etc/sysctl.conf
 sysctl -p
 
 echo " grid           soft    nproc           2047
grid           hard    nproc           16384
grid           soft    nofile          1024 
grid           hard    nofile          65536
" >> /etc/security/limits.conf


echo "
if [ \$USER = \"grid\" ] || [ \$USER = \"oracle\" ]; then
 if [ \$SHELL = "/bin/ksh" ]; then
 ulimit -p 16384
 ulimit -n 65536 
 else 
 ulimit -u 16384 -n 65536 
 fi
 umask 022
fi" >> /etc/profile


echo "
oracle hard memlock 41943040
oracle soft memlock 41943040
" >>  /etc/security/limits.conf


echo "vm.nr_hugepages=20480">>/etc/sysctl.conf
sysctl -p 

grep Huge /proc/meminfo
sleep 3

echo "
session required /lib64/security/pam_limits.so
" >>  /etc/pam.d/login 

#to set your ntp config
read -p "complete your ntp setting, yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac

echo "
10.1.1.67  lnx67
10.1.1.68  lnx68
10.1.1.167  lnx67-vip
10.1.1.168  lnx68-vip
10.1.1.169  scantest
192.178.1.67	lnx67-priv
192.178.1.68	lnx68-priv
" >> /etc/hosts

#---------------------------------------------------------------------------------
groupadd -g 1100 asmadmin
groupadd -g 1201 oper
groupadd -g 1300 asmdba
groupadd -g 1301 asmoper

useradd -u 1100 -g oinstall -G asmadmin,asmdba,asmoper grid
usermod -g oinstall -G dba,oper,asmdba oracle

mkdir -p /u01/app/oracle/11.2.0/db_1
chmod 775 /u01/app/oracle/11.2.0/db_1
mkdir -p /u01/app/grid/11.2.0/grid
chmod 775 /u01/app/grid/11.2.0/grid
mkdir -p /u01/app/grid_base
chmod 775 /u01/app/grid_base



mkdir /u01/app/oraInventory
chmod 775 /u01/app/oraInventory
chown -R grid:oinstall /u01/app/grid/
chown -R grid:oinstall /u01/app/grid_base
chown -R oracle:oinstall /u01/app/oracle/
chown -R grid:oinstall /u01/app/oraInventory



echo "ENV{ID_SERIAL}==\"360060e8007c4fb000030c4fb00000007\",SYMLINK=\"qdata/sddlmaa\",OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"660\"
ENV{ID_SERIAL}==\"360060e8007c4fb000030c4fb00000008\",SYMLINK=\"qdata/sddlmab\",OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"660\"
ENV{ID_SERIAL}==\"360060e8007c4fb000030c4fb00000009\",SYMLINK=\"qdata/sddlmac\",OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"660\"
">> /etc/udev/rules.d/99-oracle-asmdevices.rules
udevadm control --reload-rules
start_udev
ls -lL /dev/qdata/sddlma*

#to manual confirm                              
read -p "  you got your disk , yes/no?" yn           
 case $yn in                                    
        [Yy]* ) echo "continue ..."; break;;    
        [Nn]* ) exit;;                          
        * ) echo "Please answer yes or no.";;   
   esac                                         


echo "
ORACLE_SID=+ASM1
#set sid NO. depends on
export ORACLE_SID
ORACLE_BASE=/u01/app/grid_base
export ORACLE_BASE
ORACLE_HOME=/u01/app/grid/11.2.0/grid
export ORACLE_HOME
PATH=\$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:\$ORACLE_HOME/bin
export PATH
LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:\$ORACLE_HOME/lib
export LD_LIBRARY_PATH
NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export NLS_LANG
umask 022
" >> /home/grid/.bash_profile


echo "
ORACLE_SID=orcl1
#set sid NO. depends on
export ORACLE_SID
ORACLE_UNQNAME=orcl
export ORACLE_UNQNAME
ORACLE_BASE=/u01/app/oracle
export ORACLE_BASE
ORACLE_HOME=\$ORACLE_BASE/11.2.0/db_1
export ORACLE_HOME
ORA_GRID_HOME=/u01/app/grid/11.2.0/grid
export ORA_GRID_HOME
PATH=\$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:\$ORACLE_HOME/bin:$ORA_GRID_HOME/bin
export PATH
LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:$ORACLE_HOME/lib
export LD_LIBRARY_PATH
NLS_LANG=\"SIMPLIFIED CHINESE_CHINA.ZHS16GBK\"
export NLS_LANG
umask 022
" >> /home/oracle/.bash_profile


mkdir -p /u01/software/grid
mkdir -p /u01/software/db

passwd grid
passwd oracle


#-----------------------------------------------------------------------------------------------------
read -p "Please upload your Oracle softwares at /u01/software/ , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac

mv /u01/software/p13390677_112040_Linux-x86-64_3of7.zip /u01/software/grid/
mv /u01/software/p13390677_112040_Linux-x86-64_[12]of7.zip /u01/software/db/
chown -R oracle.oinstall /u01/software/db
chown -R grid.oinstall /u01/software/grid
su -  grid <<EOF
cd /u01/software/grid/ 
unzip p13390677_112040_Linux-x86-64_3of7.zip
pwd;
exit;
EOF
 
su -  oracle <<EOF

cd /u01/software/db/;
 unzip p13390677_112040_Linux-x86-64_1of7.zip
 unzip p13390677_112040_Linux-x86-64_2of7.zip
 exit;
EOF
 
 
cd  /u01/software/grid/grid/rpm
rpm -ivh cvuqdisk-1.0.9-1.rpm


scp cvuqdisk-1.0.9-1.rpm lnx68:/tmp

	

cd /u01/software/grid/grid/stage/cvu/cv/admin
cp cvu_config backup_cvu_config 

echo "modify yourself \"CV_ASSUME_DISTID=OEL6\" >> /u01/software/grid/grid/stage/cvu/cv/admin/cvu_config "  
        
#echo "CV_ASSUME_DISTID=OEL6" >> /u01/software/grid/grid/stage/cvu/cv/admin/cvu_config  
        








#node2:===================================================================================================================================================================



echo "alias bond0 bonding" > /etc/modprobe.d/bonding.conf
chkconfig --level 35 NetworkManager off
service NetworkManager stop

echo "DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
IPADDR=10.1.1.68
NETMASK=255.255.255.0
GATEWAY=10.1.1.254
USERCTL=no
BONDING_OPTS="mode=1 miimon=100"
" > /etc/sysconfig/network-scripts/ifcfg-bond0

echo "DEVICE=bond1
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.178.1.68
NETMASK=255.255.255.0
USERCTL=no
BONDING_OPTS="mode=1 miimon=100"
" > /etc/sysconfig/network-scripts/ifcfg-bond1

cp -r /etc/sysconfig/network-scripts/ /tmp 

echo "DEVICE=em1
MASTER=bond0
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em1

echo "DEVICE=em2
MASTER=bond0
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em2

echo "DEVICE=em3
MASTER=bond1
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em3


echo "DEVICE=em4
MASTER=bond1
SLAVE=yes
USERCTL=no
BOOTPROTO=none
ONBOOT=yes
" > /etc/sysconfig/network-scripts/ifcfg-em4

service network restart

#_________________________________________________________________________________________________________________________________________________________________________


cat /proc/net/bonding/bond0
#sleep 2
cat /proc/net/bonding/bond1

#to manual confirm.
read -p "correct above , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac

service iptables stop
chkconfig iptables off

echo  "
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
" > /etc/selinux/config



setenforce 0
sestatus
sleep 2


read -p "plugin your CD , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac
   
mount -o ro /dev/sr1 /media 

#to manual confirm
read -p " mount succeed , yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac
   
   
mv  /etc/yum.repos.d/* /tmp

echo "
[InstallMedia]
name=Oracle Linux 6.5
gpgcheck=0
baseurl=file:///media 
" >> /etc/yum.repos.d/media.repo

yum repolist
yum -y install xorg-x11-xauth xterm Xserver xorg-x11-utils
yum install oracle-rdbms-server-11gR2-preinstall

#to set your multipath config
read -p "complete your multipath setting, yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac



echo "
# bond1 -changed rpf 
net.ipv4.conf.bond1.rp_filter = 2
" >> /etc/sysctl.conf
sysctl -p
 
echo "grid           soft    nproc           2047
grid           hard    nproc           16384
grid           soft    nofile          1024 
grid           hard    nofile          65536
" >> /etc/security/limits.conf


echo "
if [ \$USER = \"grid\" ] || [ \$USER = \"oracle\" ]; then
 if [ \$SHELL = "/bin/ksh" ]; then
 ulimit -p 16384
 ulimit -n 65536 
 else 
 ulimit -u 16384 -n 65536 
 fi
 umask 022
fi" >> /etc/profile


echo "
oracle hard memlock 41943040
oracle soft memlock 41943040
" >>  /etc/security/limits.conf


echo "vm.nr_hugepages=76800">>/etc/sysctl.conf
sysctl -p 

grep Huge /proc/meminfo
sleep 2

echo "
session required /lib64/security/pam_limits.so
" >>  /etc/pam.d/login 


#to set your ntp config
read -p "complete your ntp setting, yes/no?" yn
 case $yn in
        [Yy]* ) echo "continue ..."; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
   esac

echo "
10.1.1.67  lnx67
10.1.1.68  lnx68
10.1.1.167  lnx67-vip
10.1.1.168  lnx68-vip
10.1.1.169  scantest
192.178.1.67	lnx67-priv
192.178.1.68	lnx68-priv
" >> /etc/hosts



#------------------------------------------------------------------------------------------------------------------------------------------------
groupadd -g 1100 asmadmin
groupadd -g 1201 oper
groupadd -g 1300 asmdba
groupadd -g 1301 asmoper
useradd -u 1100 -g oinstall -G asmadmin,asmdba,asmoper grid
usermod -g oinstall -G dba,oper,asmdba oracle

mkdir -p /u01/app/oracle/11.2.0/db_1
chmod 775 /u01/app/oracle/11.2.0/db_1
mkdir -p /u01/app/grid/11.2.0/grid
chmod 775 /u01/app/grid/11.2.0/grid
mkdir -p /u01/app/grid_base
chmod 775 /u01/app/grid_base



mkdir /u01/app/oraInventory
chmod 775 /u01/app/oraInventory
chown -R grid:oinstall /u01/app/grid/
chown -R grid:oinstall /u01/app/grid_base
chown -R oracle:oinstall /u01/app/oracle/
chown -R grid:oinstall /u01/app/oraInventory



echo "ENV{ID_SERIAL}==\"360060e8007c4fb000030c4fb00000007\",SYMLINK=\"qdata/sddlmaa\",OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"660\"
ENV{ID_SERIAL}==\"360060e8007c4fb000030c4fb00000008\",SYMLINK=\"qdata/sddlmab\",OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"660\"
ENV{ID_SERIAL}==\"360060e8007c4fb000030c4fb00000009\",SYMLINK=\"qdata/sddlmac\",OWNER=\"grid\", GROUP=\"asmadmin\", MODE=\"660\"
">> /etc/udev/rules.d/99-oracle-asmdevices.rules

udevadm control --reload-rules

start_udev

ls -lL /dev/qdata/sddlma*




echo "
ORACLE_SID=+ASM2
#set sid NO. depends on
export ORACLE_SID
ORACLE_BASE=/u01/app/grid_base
export ORACLE_BASE
ORACLE_HOME=/u01/app/grid/11.2.0/grid
export ORACLE_HOME
PATH=\$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:\$ORACLE_HOME/bin
export PATH
LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:\$ORACLE_HOME/lib
export LD_LIBRARY_PATH
NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export NLS_LANG
umask 022
" >> /home/grid/.bash_profile


echo "
ORACLE_SID=orcl2
#set sid NO. depends on
export ORACLE_SID
ORACLE_BASE=/u01/app/oracle
export ORACLE_BASE
ORACLE_HOME=\$ORACLE_BASE/11.2.0/db_1
export ORACLE_HOME
ORA_GRID_HOME=/u01/app/grid/11.2.0/grid
export ORA_GRID_HOME
PATH=\$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:\$ORACLE_HOME/bin:$ORA_GRID_HOME/bin
export PATH
LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:$ORACLE_HOME/lib
export LD_LIBRARY_PATH
NLS_LANG=\"SIMPLIFIED CHINESE_CHINA.ZHS16GBK\"
export NLS_LANG
umask 022
" >> /home/oracle/.bash_profile
cd /tmp
rpm -ivh cvuqdisk-1.0.9-1.rpm

passwd grid
passwd oracle





67:

       
--------备份恢复
---修改源库归档模式，打开归档
shutdown immediate
startup mount
alter database archivelog;
alter database open;

-----备份源端
backup as compressed backupset database FORMAT '/backup/bk_0b_%s_%p_%T' TAG=hot_db_bk_0b include current controlfile plus archivelog delete input FORMAT '/backup/bk_0b_%s_%p_%T';
run {
ALLOCATE CHANNEL ch00 TYPE disk;
ALLOCATE CHANNEL ch01 TYPE disk;
ALLOCATE CHANNEL ch02 TYPE disk;
ALLOCATE CHANNEL ch03 TYPE disk;
BACKUP as compressed backupset FILESPERSET 5 DATABASE FORMAT '/backup/bk_0b_%s_%p_%T' TAG=hot_db_bk_0b;
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
RELEASE CHANNEL ch02;
RELEASE CHANNEL ch03;
}
run {
allocate channel ch00 type disk;
allocate channel ch01 type disk;
allocate channel ch02 type disk;
allocate channel ch03 type disk;
sql 'alter system archive log current';
backup  as compressed backupset  FILESPERSET 20 archivelog  from time 'sysdate-1' format '/backup/arch%T_%u_%p.%d' tag='ARCHIVELOG';
release channel ch00;
release channel ch01;
release channel ch02;
release channel ch03;
}
run {
ALLOCATE CHANNEL ch00 TYPE disk;
backup spfile format '/backup/spfile_%d_%s_%T_dbid%I'; 
release channel ch00;
}
 
----将备份文件传输至目标端


----

        










run {
ALLOCATE CHANNEL ch00 TYPE disk;
backup spfile format '/backup/spfile_%d_%s_%T_dbid%I'; 
release channel ch00;
}
