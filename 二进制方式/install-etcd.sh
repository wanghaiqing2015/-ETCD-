#
# 搭建ETCD三节点集群
#

function set_etcd_conf(){
if [ "$1" == etcd1 ]; then
    THIS_NAME=etcd1
    THIS_IP=${HOST_1}
    echo -e "\033[42;37;1m开始配置$1\033[0m"
elif [ "$1" == etcd2 ]; then
    THIS_NAME=etcd2
    THIS_IP=${HOST_2}
    echo -e "\033[42;37;1m开始配置$1\033[0m"
elif [ "$1" == etcd3 ]; then
    THIS_NAME=etcd3
    THIS_IP=${HOST_3}
    echo -e "\033[42;37;1m开始配置$1\033[0m"
else
    echo -e "\033[41;37;1m参数不对，请确认，比如etcd1、etcd2、etcd3\033[0m"
    return 1
fi

cat > /etc/etcd/etcd.conf <<EOF
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#监听URL，用于与其他节点通讯
ETCD_LISTEN_PEER_URLS="https://0.0.0.0:2380"

#告知客户端的URL, 也就是服务的URL
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379"

#表示监听其他节点同步信号的地址
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${THIS_IP}:2380"

#–advertise-client-urls 告知客户端的URL, 也就是服务的URL，tcp2379端口用于监听客户端请求
ETCD_ADVERTISE_CLIENT_URLS="https://${THIS_IP}:2379"

#启动参数配置
ETCD_NAME="${THIS_NAME}"
ETCD_INITIAL_CLUSTER="etcd1=https://${HOST_1}:2380,etcd2=https://${HOST_2}:2380,etcd3=https://${HOST_3}:2380"
ETCD_INITIAL_CLUSTER_STATE="${CLUSTER_STATE}"

#[security]

ETCD_CERT_FILE="/opt/cfssl/server.pem"
ETCD_KEY_FILE="/opt/cfssl/server-key.pem"
ETCD_TRUSTED_CA_FILE="/opt/cfssl/ca.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_PEER_CERT_FILE="/opt/cfssl/member1.pem"
ETCD_PEER_KEY_FILE="/opt/cfssl/member1-key.pem"
ETCD_PEER_TRUSTED_CA_FILE="/opt/cfssl/ca.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
EOF

echo -e "\033[42;37;1m配置$1完成\033[0m"
}

# 没有输入参数，报错
if [ "$#" == 0 ]; then
    echo -e "\033[41;37;1m请输入参数，比如etcd1、etcd2、etcd3\033[0m"
    exit 1
fi

# ntpdate 时间同步
yum install ntp -y
ntpdate time1.aliyun.com

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
sed -i -e  's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# 更新源
# rm -rf /etc/yum.repos.d/*
# curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
# curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo

# 安装etcd
which etcd
if [ "$?" == 1 ]; then
    # yum install etcd -y
    rpm -ivh etcd-3.3.11-2.el7.centos.x86_64.rpm
fi


# 解压证书
tar zxvf cfssl.tar.gz -C /opt/

# 删除存储目录
rm -rf /var/lib/etcd/default.etcd/*
 
# 设置全局变量
export CLUSTER_STATE=new
export NAME_1=etcd1
export NAME_2=etcd2
export NAME_3=etcd3
export HOST_1=192.168.31.200
export HOST_2=192.168.31.243
export HOST_3=192.168.31.246
export CLUSTER=${NAME_1}=https://${HOST_1}:2380,${NAME_2}=https://${HOST_2}:2380,${NAME_3}=https://${HOST_3}:2380
 
# 修改配置文件
set_etcd_conf $1

exit 0

# 注备好之后，三台机器要同时启动服务才行
systemctl restart etcd
systemctl enable  etcd
systemctl status  etcd

export ETCDCTL_API=3   
etcdctl --endpoints=https://192.168.31.200:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem member list
etcdctl --endpoints=https://192.168.31.200:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint health
etcdctl --endpoints=https://192.168.31.200:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint status
etcdctl --endpoints=https://192.168.31.200:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem version

etcdctl --endpoints=https://192.168.31.200:2379,https://192.168.31.243:2379,https://192.168.31.246:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem member list
etcdctl --endpoints=https://192.168.31.200:2379,https://192.168.31.243:2379,https://192.168.31.246:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint health
etcdctl --endpoints=https://192.168.31.200:2379,https://192.168.31.243:2379,https://192.168.31.246:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint status
etcdctl --endpoints=https://192.168.31.200:2379,https://192.168.31.243:2379,https://192.168.31.246:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem version
 