#!/bin/bash
#author：yuxiaoguang
#date：2016/5/22
 
#使用yum -y update更新系统时不升级内核
yum -y update
 
#删除没用的系统默认用户(不能删除postfix账号，此用户会影响到tar压缩备份)
userdel adm
userdel lp
userdel sync
userdel shutdown
userdel halt
userdel news
userdel uucp
userdel operator
userdel games
userdel gopher
#删除没用的系统默认组
groupdel adm
groupdel lp
groupdel news
groupdel uucp
groupdel games
groupdel dip
groupdel pppusers
groupdel popusers
groupdel slipusers
 
#锁定用户
passwd -l mail
passwd -l nobody
passwd -l ftp
 
#用chattr命令防止系统中某个关键文件被修改，chattr -i可以恢复
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/hosts
chattr +i /etc/resolv.conf
chattr +i /etc/fstab
chattr +i /etc/sudoers
 
 
#安装系统必需软件包
yum -y install make gcc-c++ cmake bison-devel ncurses-devel net-snmp sysstat dstat iotop lrzsz flex byacc libpcap libpcap-devel nfs-utils ntp zip unzip xz wget vim lsof bison openssh-clients
 
#同步时间
ntpdate cn.pool.ntp.org
hwclock --systohc
echo -e "0 0 * * * /usr/sbin/ntpdate cn.pool.ntp.org > /dev/null" >> /var/spool/cron/root
 
#系统服务
#chkconfig anacron off  (禁用后会出现mysql初始化不成功)
chkconfig auditd off
chkconfig iptables on
chkconfig ip6tables off
chkconfig snmpd on
chkconfig ntpd on
chkconfig ntpdate on
chkconfig cups off
chkconfig acpid off
chkconfig apmd off
chkconfig atd off
chkconfig autofs off
chkconfig avahi-daemon off
chkconfig bluetooth off
chkconfig cpuspeed off
chkconfig firstboot off
chkconfig gpm off
chkconfig haldaemon off
chkconfig hidd off
chkconfig hplip off
chkconfig isdn off
chkconfig lm_sensors off
chkconfig messagebus off
 
#关闭selinux
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
 
#更改系统最大进程数
cat >> /etc/security/limits.conf << EOF
* soft nproc unlimited
* hard nproc unlimited
* soft nofile 65535
* hard nofile 65535
EOF
#更改系统最大进程数
cat >> /etc/security/limits.d/90-nproc.conf << EOF
 
* soft nproc unlimited
 
* hard nproc unlimited
 
* soft nofile 65535
* hard nofile 65535
EOF
 
#可以实现详细记录登录过系统的用户、IP地址、shell命令以及详细操作时间等，并将这些信息以文件的形式保存在一个安全的地方，以供系统审计和故障排查。
cat >> /etc/profile << EOF
USER_IP=`who -u am i 2>/dev/null| awk '{print $NF}'|sed -e 's/[()]//g'`
HISTDIR=/usr/etc/.history
if [ -z $USER_IP ]
then
USER_IP=`hostname`
fi
if [ ! -d $HISTDIR ]
then
mkdir -p $HISTDIR
chmod 777 $HISTDIR
fi
if [ ! -d $HISTDIR/${LOGNAME} ]
then
mkdir -p $HISTDIR/${LOGNAME}
chmod 300 $HISTDIR/${LOGNAME}
fi
export HISTSIZE=2000
DT=`date +%Y%m%d_%H%M%S`
export HISTFILE="$HISTDIR/${LOGNAME}/${USER_IP}.history.$DT"
export HISTTIMEFORMAT="[%Y.%m.%d %H:%M:%S] "
chmod 600 $HISTDIR/${LOGNAME}/*.history* 2>/dev/null
 
ulimit -SHn 65535
ulimit -SHu unlimited
ulimit -SHd unlimited
ulimit -SHm unlimited
ulimit -SHs unlimited
ulimit -SHt unlimited
ulimit -SHv unlimited
EOF
 
#更改vi别名、更改默认显示行号、显示终端颜色
cat >>  /etc/bashrc << EOF
EXINIT='set nu showmode expandtab softtabstop=4 shiftwidth=4'
export EXINIT
EDITOR=vim
export EDITOR
alias vi='vim'
PS1='\[\033[01;32m\][\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;31m\]\h \[\033[01;33m\]\w\[\033[01;32m\]]\$ \e[0m'
EOF
source /etc/bashrc
 
#优化系统内核sysctl.conf
modprobe bridge
lsmod|grep bridge
modprobe ip_conntrack
 
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_tw_recycle = 1 
net.ipv4.tcp_fin_timeout = 5 
net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_timestamps = 0 
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 1 
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_keepalive_time = 30
net.core.rmem_max = 8388608
net.core.rmem_default = 65536
net.core.wmem_max = 8388608
net.core.wmem_default = 65536
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65536 8388608
vm.swappiness =5
EOF
sysctl -p
 
#隐藏服务器系统信息
mv  /etc/issue /etc/issuebak
mv  /etc/issue.net   /etc/issue.netbak
 
#安装htop
cd /soft
wget -c http://hisham.hm/htop/releases/1.0.3/htop-1.0.3.tar.gz 
tar zxvf htop-1.0.3.tar.gz
cd htop-1.0.3
./configure
make && make install
rm -rf /soft/htop-1.0.3
 
#安装iftop
cd /soft
wget -c http://www.ex-parrot.com/pdw/iftop/download/iftop-0.17.tar.gz
tar zxvf iftop-0.17.tar.gz
cd iftop-0.17
./configure
make && make install
rm -rf /soft/iftop-0.17
