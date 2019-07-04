# client certificate： 用于服务端认证客户端,例如etcdctl、etcd proxy、fleetctl、docker客户端
# server certificate: 服务端使用，客户端以此验证服务端身份,例如docker服务端、kube-apiserver
# peer certificate: 双向证书，用于etcd集群成员间通信

# https://www.centos.bz/2017/09/k8s部署之使用CFSSL创建证书/
 
# 安装cfssl
which cfssl
if [ "$?" == 1 ]; then
    echo 正在下载cfssl签名工具
    curl -fLo /usr/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    curl -fLo /usr/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    chmod +x /usr/bin/{cfssl,cfssljson}
fi

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
 
# 设置证书权限
chmod 666 /opt/cfssl/*

# 打包证书
cd /opt
tar zcvf cfssl.tar.gz cfssl/
  