#!/bin/bash
## from： http://blog.chinaunix.net/uid-23916356-id-5702016.html
# 此脚本用于初始化系统，也就是刚刚配置完网卡的服务器用于初始化.
## This is system init shell script.
## Writen by zhunzhun.zeng 2013-06-18
cat << EOF
+------------------------------------------------------------------+
| ***Welcome to CentOS System init*** |
+------------------------------------------------------------------+
EOF
echo -e "\033[33;5m注意此脚本只适合同时带外网和内网IP地址的服务器。\033[0m";
choose="no yes"
echo -e "\033[31;1m请确认要初始化这台服务器的操作系统配置？\033[0m";
select comfirm in $choose
do
if [ "${comfirm}" != "yes" ]; then
echo "初始化结束";
exit 0;
fi
break;
done;
OS=`cat /etc/redhat-release | awk '{print $1}'`
VER=`cat /etc/redhat-release | awk '{print $3}' | awk -F'.' '{print $1}'`
if [ $OS != 'CentOS' ] || [ $VER != '6' ];then
echo -e '\033[31;1mThe current system does not match, the script shell exits!\033[0m'
exit
else
echo -e '\033[34;1m开始初始化操作系统中......\033[0m'
fi
###关闭NetworkManager服务
/etc/init.d/NetworkManager stop > /dev/null 2>&1 && chkconfig NetworkManager off
if [ $? = '0' ];then
echo -e '\033[32;1m1.NetworkManager服务已关闭\033[0m'
fi
###创建目录
mkdir /root/{config,shell,software} > /dev/null 2>&1
if [ $? = '0' ];then
echo -e '\033[32;1m2.创建目录完成\033[0m'
else
echo -e '\033[32;1m2.目录已经存在\033[0m'
fi
###关闭Selinux服务
setenforce 0 > /dev/null 2>&1 && sed -i s/"SELINUX=enforcing"/"SELINUX=disabled"/g /etc/sysconfig/selinux
echo -e '\033[32;1m3.Selinux已关闭\033[0m'
###开始创建软链接
ln -s /etc/crontab /root/config/ > /dev/null 2>&1
ln -s /etc/hosts /root/config/ > /dev/null 2>&1
ln -s /etc/sysconfig/iptables /root/config/ > /dev/null 2>&1
ln -s /etc/security/limits.conf /root/config/ > /dev/null 2>&1
ln -s /etc/rc.local /root/config/ > /dev/null 2>&1
ln -s /etc/resolv.conf /root/config/ > /dev/null 2>&1
ln -s /etc/selinux/config /root/config/ > /dev/null 2>&1
ln -s /etc/ssh/sshd_config /root/config/ > /dev/null 2>&1
ln -s /etc/sysctl.conf /root/config/ > /dev/null 2>&1
ln -s /etc/yum.repos.d /root/config/ > /dev/null 2>&1
echo -e '\033[32;1m4.软链接创建完成\033[0m'
###配置DNS解析
echo "" > /etc/resolv.conf
echo "nameserver 192.168.168.229" > /etc/resolv.conf
echo "nameserver 202.106.0.20" >> /etc/resolv.conf
echo -e '\033[32;1m5.DNS配置完成\033[0m'
###配置计划任务
CRON=`cat /etc/crontab | grep "ntp.puppet.com" | grep -v grep | wc -l`
if [ $CRON -eq "0" ];then
sed -i "15 a\*/5 * * * * root ntpdate ntp.puppet.com > /dev/null 2>&1" /etc/crontab
fi
echo -e '\033[32;1m6.计划任务配置完成\033[0m'
###安装软件源
YUM=`ls -l /etc/yum.repos.d/ | grep -e epel.repo -e nginx.repo -e remi.repo | wc -l`
if [ $YUM -eq "0" ];then
rpm -ivf http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm > /dev/null 2>&1
rpm -ivf http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm > /dev/null 2>&1
rpm -ivf http://rpms.famillecollet.com/enterprise/remi-release-6.rpm > /dev/null 2>&1
fi
echo -e '\033[32;1m7.软件源安装完成\033[0m'
###安装软件包
SOFT=`rpm -qa gcc openssl-devel rpcbind vim telnet openssh-clients rsync zlib-devel | wc -l`
if [ $SOFT -eq "0" ];then
yum install -y gcc openssl-devel rpcbind vim telnet openssh-clients rsync zlib-devel > /dev/null 2>&1
fi
echo -e '\033[32;1m8.软件包安装完成\033[0m'
###配置登录显示
echo "Welcome to visit prize.the server!" > /etc/motd
echo -e '\033[32;1m9.登录显示配置完成\033[0m'
###配置ssh服务
sed -i s/'#UseDNS yes'/'UseDNS no'/g /etc/ssh/sshd_config
sed -i s/'GSSAPIAuthentication yes'/'GSSAPIAuthentication no'/g /etc/ssh/sshd_config
mkdir /root/.ssh > /dev/null 2>&1
echo "ssh-rsa AAAAB3NzaC1yc3EAAAABIwAAAQEAm3gIM+Lk3DUZ5cM8swTrTFty9iaSCW+3YDPY5f6QayPB/1zS19pD3jZgYi6neO64FUj23Z0u7yKIC2GQciXaYULFCsIPnB7crB9YYoI9RdrcAwiXotWp4ZaysugRrltddqdFLkUyZBjoegmSzBQW5ENUfzDIbsi6P0Bk4ep1/hLDrRszg9r8sUHrElRj0vt1b0bZpmbTon4iCQa8ne8MILXogVcEHg2yfiZsiXBobu/6w7lkW2TsXu+yNMjml1J8f5mbqKWq1qLcdoxQ9Asscx/VfzsB3aIBg1vSVwDwa+9mA1stJwdnhcxTEZFB9Zz8HKOj66Lfmq8elxt6w== root@mirror" > /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApISEFRv54KtuJ2a6PIhQuL+r9Wp35FK9MUgK3Z8taBSQsWVju6ArFPAUn2Os/dmC0yS67EIHMe5qVHocC/dTQyl2khR1CwHwUU32UOBWxSH+WDbOT1CpaSXiGQAxyr0Ne5UynPNSYQkKD/8E17UHYE5tbgQ0aOf+URpq6KGVXejQm1jAuseYijELuV4Y27QXcgnZ5YWuauzPDYHYNgdwqdqHEe+MhXKa4r3ALeBQn6VWCcLe7YH8ZQ1v6BcnsB+C21Xclz9N6niQgcm54N40sSYBCCM9ELxirfwAGJ3GfP4fNZGgvHY55ym1807mfZ4cAGykM9tAaF6L3vxxx== root@backup.puppet.com" >> /root/.ssh/authorized_keys
sed -i s/'PasswordAuthentication yes'/'PasswordAuthentication no'/g /etc/ssh/sshd_config
/etc/init.d/sshd restart > /dev/null 2>&1
echo -e '\033[32;1m10.ssh服务配置完成\033[0m'
###配置打开连接数
LIMIT=`cat /etc/security/limits.conf | grep 65535 | grep -v grep | wc -l`
if [ $LIMIT -eq "0" ];then
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf
echo "* soft nproc 65535" >> /etc/security/limits.conf
echo "* hard nproc 65535" >> /etc/security/limits.conf
fi
echo -e '\033[32;1m11.打开文件数配置完成\033[0m'
###配置防火墙
iptables-save > /etc/sysconfig/iptables
/etc/init.d/iptables restart > /dev/null 2>&1
echo -e '\033[32;1m12.防火墙配置完成\033[0m'
###修改内核参数
ROW=`cat /etc/sysctl.conf | wc -l`
if [ $ROW = "40" ];then
cp /etc/sysctl.conf /etc/sysctl.conf.default
cat > /etc/sysctl.conf << EOF
# Kernel sysctl configuration file for Red Hat Linux
#
# For binary values, 0 is disabled, 1 is enabled. See sysctl(8) and
# sysctl.conf(5) for more details.
# Controls IP packet forwarding
net.ipv4.ip_forward = 0
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_dynaddr = 0
net.ipv4.ip_nonlocal_bind = 0
net.ipv4.ip_no_pmtu_disc = 0
net.ipv4.ip_default_ttl = 64
# Controls source route verification
net.ipv4.conf.default.rp_filter = 1
# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0
# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 134217728
# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1
# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 196608 262144 393216
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_slow_start_after_idle = 1
net.ipv4.tcp_dma_copybreak = 4096
net.ipv4.tcp_workaround_signed_windows = 0
net.ipv4.tcp_base_mss = 512
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_abc = 0
net.ipv4.tcp_congestion_control = bic
net.ipv4.tcp_tso_win_divisor = 3
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_low_latency = 0
net.ipv4.tcp_frto = 0
net.ipv4.tcp_adv_win_scale = 2
net.ipv4.tcp_app_win = 31
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_reordering = 3
net.ipv4.tcp_fack = 1
net.ipv4.tcp_orphan_retries = 0
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_stdurg = 0
net.ipv4.tcp_abort_on_overflow = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_retries2 = 15
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_keepalive_intvl = 75
net.ipv4.tcp_keepalive_probes = 9
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_retrans_collapse = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
# Disable netfilter on bridges.
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.udp_wmem_min = 4096
net.ipv4.udp_rmem_min = 4096
net.ipv4.udp_mem = 774240 1032320 1548480
vm.swappiness = 3
net.ipv4.cipso_rbm_strictvalid = 1
net.ipv4.cipso_rbm_optfmt = 0
net.ipv4.cipso_cache_bucket_size = 10
net.ipv4.cipso_cache_enable = 1
net.ipv4.inet_peer_gc_maxtime = 120
net.ipv4.inet_peer_gc_mintime = 10
net.ipv4.inet_peer_maxttl = 600
net.ipv4.inet_peer_minttl = 120
net.ipv4.inet_peer_threshold = 65664
net.ipv4.igmp_max_msf = 10
net.ipv4.igmp_max_memberships = 20
net.ipv4.route.secret_interval = 600
net.ipv4.route.min_adv_mss = 256
net.ipv4.route.min_pmtu = 552
net.ipv4.route.mtu_expires = 600
net.ipv4.route.gc_elasticity = 8
net.ipv4.route.error_burst = 5000
net.ipv4.route.error_cost = 1000
net.ipv4.route.redirect_silence = 20480
net.ipv4.route.redirect_number = 9
net.ipv4.route.redirect_load = 20
net.ipv4.route.gc_interval = 60
net.ipv4.route.gc_timeout = 300
net.ipv4.route.gc_min_interval_ms = 500
net.ipv4.route.gc_min_interval = 0
net.ipv4.route.max_size = 4194304
net.ipv4.route.gc_thresh = 262144
net.ipv4.icmp_ratemask = 6168
net.ipv4.icmp_ratelimit = 1000
net.ipv4.icmp_errors_use_inbound_ifaddr = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.ipfrag_max_dist = 64
net.ipv4.ipfrag_secret_interval = 600
net.ipv4.ipfrag_time = 30
net.ipv4.ipfrag_low_thresh = 196608
net.ipv4.ipfrag_high_thresh = 262144
EOF
sysctl -p
fi
echo -e '\033[32;1m13.内核参数配置完成\033[0m'
echo -e '\033[34;1m这台服务器系统初始化已完成！\033[0m'
