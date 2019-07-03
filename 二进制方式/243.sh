
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
sed -i -e  's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# 更新源
rm -rf /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
 
tar zxvf cfssl.tar.gz -C /opt/

# 安装etcd
yum install etcd -y

rm -rf /var/lib/etcd/default.etcd/*

cat > /etc/etcd/etcd.conf <<EOF
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#监听URL，用于与其他节点通讯
ETCD_LISTEN_PEER_URLS="https://0.0.0.0:2380"

#告知客户端的URL, 也就是服务的URL
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379"

#表示监听其他节点同步信号的地址
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.31.243:2380"

#–advertise-client-urls 告知客户端的URL, 也就是服务的URL，tcp2379端口用于监听客户端请求
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.31.243:2379"

#启动参数配置
ETCD_NAME="etcd1"
ETCD_INITIAL_CLUSTER="etcd1=https://192.168.31.243:2380,etcd2=https://192.168.31.244:2380,etcd3=https://192.168.31.245:2380"
ETCD_INITIAL_CLUSTER_STATE="new"

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

# 注备好之后，三台机器要同时启动服务才行
systemctl restart etcd
systemctl status  etcd
systemctl enable  etcd

export ETCDCTL_API=3   
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem member list
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint health
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint status
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem version

etcdctl --endpoints=https://192.168.31.243:2379,https://192.168.31.244:2379,https://192.168.31.245:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem member list
etcdctl --endpoints=https://192.168.31.243:2379,https://192.168.31.244:2379,https://192.168.31.245:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint health
etcdctl --endpoints=https://192.168.31.243:2379,https://192.168.31.244:2379,https://192.168.31.245:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem endpoint status
etcdctl --endpoints=https://192.168.31.243:2379,https://192.168.31.244:2379,https://192.168.31.245:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem version

exit 0
 