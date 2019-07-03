
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
sed -i -e  's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# 更新源
rm -rf /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
 
# 安装cfssl
curl -s -L -o /usr/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o /usr/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/bin/{cfssl,cfssljson}

# 初始化证书颁发机构
rm -rf /opt/cfssl
mkdir /opt/cfssl
cd /opt/cfssl
cfssl print-defaults config > ca-config.json
cfssl print-defaults csr > ca-csr.json

cat > ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

cat > ca-csr.json <<EOF
{
    "CN": "My own CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "US",
            "L": "CA",
            "O": "My Company Name",
            "ST": "San Francisco",
            "OU": "Org Unit 1",
            "OU": "Org Unit 2"
        }
    ]
}
EOF

# 生成 CA 证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# 生成服务器端证书
echo '{"CN":"coreos1","hosts":["192.168.31.243","192.168.31.244","192.168.31.245","127.0.0.1"],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server -hostname="192.168.31.243,192.168.31.244,192.168.31.245,127.0.0.1,server" - | cfssljson -bare server

# 生成对等证书
echo '{"CN":"member1","hosts":["192.168.31.243","192.168.31.244","192.168.31.245","127.0.0.1"],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.31.243,192.168.31.244,192.168.31.245,127.0.0.1,server,member1" - | cfssljson -bare member1

# 生成客户端证书
echo '{"CN":"client","hosts":["192.168.31.243","192.168.31.244","192.168.31.245","127.0.0.1"],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client - | cfssljson -bare client

mkdir -pv /etc/ssl/etcd/
/bin/cp -f  /opt/cfssl/* /etc/ssl/etcd/
chmod 666 /etc/ssl/etcd/*-key.pem
/bin/cp -f  /opt/cfssl/ca.pem /etc/ssl/certs/

# 更新系统证书库
update-ca-trust

# 安装etcd
yum install etcd -y

rm -rf /var/lib/etcd/default.etcd/*

cat > /etc/etcd/etcd.conf <<EOF
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#监听URL，用于与其他节点通讯
ETCD_LISTEN_PEER_URLS="https://0.0.0.0:2380"

#告知客户端的URL, 也就是服务的URL
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379,https://0.0.0.0:4001"

#表示监听其他节点同步信号的地址
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.31.243:2380"

#–advertise-client-urls 告知客户端的URL, 也就是服务的URL，tcp2379端口用于监听客户端请求
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.31.243:2379"

#启动参数配置
ETCD_NAME="etcd1"
ETCD_INITIAL_CLUSTER="etcd1=https://192.168.31.243:2380,etcd2=https://192.168.31.244:2380,etcd3=https://192.168.31.245:2380"
ETCD_INITIAL_CLUSTER_STATE="new"

#[security]

ETCD_CERT_FILE="/etc/ssl/etcd/server.pem"
ETCD_KEY_FILE="/etc/ssl/etcd/server-key.pem"
ETCD_TRUSTED_CA_FILE="/etc/ssl/etcd/ca.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_PEER_CERT_FILE="/etc/ssl/etcd/member1.pem"
ETCD_PEER_KEY_FILE="/etc/ssl/etcd/member1-key.pem"
ETCD_PEER_TRUSTED_CA_FILE="/etc/ssl/etcd/ca.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
#[logging]
ETCD_DEBUG="true"
ETCD_LOG_PACKAGE_LEVELS="etcdserver=WARNING,security=DEBUG"
EOF

systemctl restart  etcd
systemctl status  etcd
systemctl enable  etcd


curl --cacert /etc/ssl/etcd/ca.pem --cert /etc/ssl/etcd/client.pem --key /etc/ssl/etcd/client-key.pem https://127.0.0.1:2379/health


etcdctl --endpoints=https://192.168.31.243:2379 --ca-file=/etc/ssl/etcd/ca.pem --cert-file=/etc/ssl/etcd/client.pem --key-file=/etc/ssl/etcd/client-key.pem  member list
 
 


export ETCDCTL_API=3   
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem member list 
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem put aaa 111
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem get aaa

etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem endpoint health
etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem endpoint status

etcdctl --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem version

# journalctl -f -t etcd
# journalctl -u etcd
 
etcdctl --debug --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem   member add etcd2 https://192.168.31.244:2380 

etcdctl --debug --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem   member add etcd3 https://192.168.31.245:2380

etcdctl --debug --endpoints=https://192.168.31.243:2379 --cacert=/etc/ssl/etcd/ca.pem --cert=/etc/ssl/etcd/client.pem --key=/etc/ssl/etcd/client-key.pem   member remove 7368fbbb002ba231


export ETCDCTL_API=2
etcdctl --debug --endpoints=https://192.168.31.243:2379 --ca-file=/etc/ssl/etcd/ca.pem --cert-file=/etc/ssl/etcd/client.pem --key-file=/etc/ssl/etcd/client-key.pem   member add etcd2 https://192.168.31.244:2380 

etcdctl --debug --endpoints=https://192.168.31.243:2379 --ca-file=/etc/ssl/etcd/ca.pem --cert-file=/etc/ssl/etcd/client.pem --key-file=/etc/ssl/etcd/client-key.pem   member add etcd3 https://192.168.31.245:2380

etcdctl --debug --endpoints=https://192.168.31.243:2379 --ca-file=/etc/ssl/etcd/ca.pem --cert-file=/etc/ssl/etcd/client.pem --key-file=/etc/ssl/etcd/client-key.pem   member remove 7368fbbb002ba231

etcdctl --debug --endpoints=https://192.168.31.243:2379 --ca-file=/etc/ssl/etcd/ca.pem --cert-file=/etc/ssl/etcd/client.pem --key-file=/etc/ssl/etcd/client-key.pem   member list 