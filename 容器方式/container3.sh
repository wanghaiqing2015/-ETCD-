
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
sed -i -e  's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
systemctl start docker && systemctl enable docker
docker pull quay.io/coreos/etcd:v3.0.0

docker rm -f etcd
 
# For each machine
ETCD_VERSION=v3.0.0
TOKEN=my-etcd-token
CLUSTER_STATE=new
NAME_1=etcd-node-0
NAME_2=etcd-node-1
NAME_3=etcd-node-2
HOST_1=192.168.31.243
HOST_2=192.168.31.244
HOST_3=192.168.31.245
CLUSTER=${NAME_1}=https://${HOST_1}:2380,${NAME_2}=https://${HOST_2}:2380,${NAME_3}=https://${HOST_3}:2380

# For node 1
docker rm -f etcd
THIS_NAME=${NAME_1}
THIS_IP=${HOST_1}
sudo docker run \
    -v /opt/cfssl:/opt/cfssl \
    --net=host \
    --name etcd quay.io/coreos/etcd:${ETCD_VERSION} \
    /usr/local/bin/etcd \
    --data-dir=data.etcd --name ${THIS_NAME} \
    --initial-advertise-peer-urls https://${THIS_IP}:2380 --listen-peer-urls https://0.0.0.0:2380 \
    --advertise-client-urls https://${THIS_IP}:2379 --listen-client-urls https://0.0.0.0:2379 \
    --initial-cluster ${CLUSTER} \
    --client-cert-auth \
    --cert-file /opt/cfssl/server.pem \
    --key-file /opt/cfssl/server-key.pem \
    --trusted-ca-file /opt/cfssl/ca.pem \
    --peer-client-cert-auth \
    --peer-cert-file /opt/cfssl/member1.pem \
    --peer-key-file /opt/cfssl/member1-key.pem \
    --peer-trusted-ca-file /opt/cfssl/ca.pem \
    --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}
    
# For node 2
docker rm -f etcd
THIS_NAME=${NAME_2}
THIS_IP=${HOST_2}
sudo docker run \
    -v /opt/cfssl:/opt/cfssl \
    --net=host \
    --name etcd quay.io/coreos/etcd:${ETCD_VERSION} \
    /usr/local/bin/etcd \
    --data-dir=data.etcd --name ${THIS_NAME} \
    --initial-advertise-peer-urls https://${THIS_IP}:2380 --listen-peer-urls https://0.0.0.0:2380 \
    --advertise-client-urls https://${THIS_IP}:2379 --listen-client-urls https://0.0.0.0:2379 \
    --initial-cluster ${CLUSTER} \
    --client-cert-auth \
    --cert-file /opt/cfssl/server.pem \
    --key-file /opt/cfssl/server-key.pem \
    --trusted-ca-file /opt/cfssl/ca.pem \
    --peer-client-cert-auth \
    --peer-cert-file /opt/cfssl/member1.pem \
    --peer-key-file /opt/cfssl/member1-key.pem \
    --peer-trusted-ca-file /opt/cfssl/ca.pem \
    --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}
    
# For node 3
docker rm -f etcd
THIS_NAME=${NAME_3}
THIS_IP=${HOST_3}
sudo docker run \
    -v /opt/cfssl:/opt/cfssl \
    --net=host \
    --name etcd quay.io/coreos/etcd:${ETCD_VERSION} \
    /usr/local/bin/etcd \
    --data-dir=data.etcd --name ${THIS_NAME} \
    --initial-advertise-peer-urls https://${THIS_IP}:2380 --listen-peer-urls https://0.0.0.0:2380 \
    --advertise-client-urls https://${THIS_IP}:2379 --listen-client-urls https://0.0.0.0:2379 \
    --initial-cluster ${CLUSTER} \
    --client-cert-auth \
    --cert-file /opt/cfssl/server.pem \
    --key-file /opt/cfssl/server-key.pem \
    --trusted-ca-file /opt/cfssl/ca.pem \
    --peer-client-cert-auth \
    --peer-cert-file /opt/cfssl/member1.pem \
    --peer-key-file /opt/cfssl/member1-key.pem \
    --peer-trusted-ca-file /opt/cfssl/ca.pem \
    --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}
    
docker exec etcd /bin/sh -c "export ETCDCTL_API=3 && /usr/local/bin/etcdctl --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem --endpoints=https://192.168.31.243:2379 member list"
