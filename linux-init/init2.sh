#!/bin/bash
# Author:JuChangfei
# BLOG:http://changfei.blog.51cto.com
  
if [ `whoami` != "root" ];then
echo "please use root!"
exit 1
fi
 
#Common installation package
yum -y install sysstat iptraf curl curl-devel ntp wget lsof  strace lrzsz cmake setuptool
 
#set runlevel to 3
sed -i 's/id:.*$/id:3:initdefault:/g' /etc/inittab
 
#set ulimit to 102400
checklimits=`grep '* - nofile' /etc/security/limits.conf`
if [ "$checklimits" == "" ] ; then
echo '* - nofile 102400' >> /etc/security/limits.conf
fi
 
#disable selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
 
#set time zone
echo 'ZONE="Asia/Shanghai"' > /etc/sysconfig/clock
 
#set ntpdate server
ntptmp=`crontab -l |grep 'ntpdate'`
if [ "$ntptmp" == "" ];then
echo "30 00 * * * /usr/sbin/ntpdate ntp.server.com" >> /var/spool/cron/root
fi
 
#30 minutes of no activity, automatically exit
echo "TMOUT=1800" >> /etc/profile
 
#disable ipv6
echo "alias net-pf-10 off" >> /etc/modprobe.conf
echo "alias ipv6 off" >> /etc/modprobe.conf
/sbin/chkconfig --level 35 ip6tables off
sed -i "s/NETWORKING_IPV6=yes/NETWORKING_IPV6=no/g" /etc/sysconfig/network
 
#turnoff service
for i in `ls /etc/rc3.d/S*`
do
 serviename=`echo $i|cut -c 15-`
 echo $serviename
 case $serviename in
 crond | irqbalance | microcode_ctl | network | random | sshd | syslog | auditd | cpuspeed | xinetd | mon | partmon | messagebus| udev-post | sshd | rsyslog | syslog )
 echo "Skip This Service!"
 ;;
 *)
 echo "$serviename off"
 chkconfig --level 235 $serviename off
 service $serviename stop
 ;;
 esac
done
 
#Set by the history view history command displays only 10
sed -i "s/HISTSIZE=1000/HISTSIZE=10/" /etc/profile
 
#ssh security reinforce
#只允许SSH2方式的连
sed -i "s/#Protocol 2,1/Protocol 2/" /etc/ssh/sshd_config 
#指定每个连接最大允许的认证次数。默认值是 6
sed -i "s/#MaxAuthTries 6/MaxAuthTries 6/" /etc/ssh/sshd_config 
#不使用DNS解析
sed -i  "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config 
#不允许空密码用户login（仅仅是明文密码方式，非证书方式）。
sed -i  "s/#PermitEmptyPasswords no/PermitEmptyPasswords no/" /etc/ssh/sshd_config
# 启用RSA 认证。
sed -i  "s/#RSAAuthentication yes/RSAAuthentication yes/" /etc/ssh/sshd_config
# 启用公钥认证。
sed -i  "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config
#禁止明文密码登陆。
sed -i  "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
 
#set sysctl.conf
cat >> /etc/sysctl.conf <<EOF
#init sysctl
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535
EOF
/sbin/sysctl -p
 
#set locale
true > /etc/sysconfig/i18n
cat >>/etc/sysconfig/i18n <<EOF
LANG="zh_CN.GB18030"
LANGUAGE="zh_CN.GB18030:zh_CN.GB2312:zh_CN"
SUPPORTED="zh_CN.UTF-8:zh_CN:zh:en_US.UTF-8:en_US:en"
SYSFONT="lat0-sun16"
EOF
