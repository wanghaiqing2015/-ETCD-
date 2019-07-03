cat > /etc/etcd/etcd.conf <<EOF
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#监听URL，用于与其他节点通讯
ETCD_LISTEN_PEER_URLS="https://0.0.0.0:2380"

#告知客户端的URL, 也就是服务的URL
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379"

#表示监听其他节点同步信号的地址
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.31.245:2380"

#–advertise-client-urls 告知客户端的URL, 也就是服务的URL，tcp2379端口用于监听客户端请求
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.31.245:2379"

#启动参数配置
ETCD_NAME="etcd3"
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