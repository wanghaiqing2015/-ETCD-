# client certificate： 用于服务端认证客户端,例如etcdctl、etcd proxy、fleetctl、docker客户端
# server certificate: 服务端使用，客户端以此验证服务端身份,例如docker服务端、kube-apiserver
# peer certificate: 双向证书，用于etcd集群成员间通信

# https://www.centos.bz/2017/09/k8s部署之使用CFSSL创建证书/
 
# 安装cfssl
which cfssl
if [ "$?" == 1 ]; then
    echo 正在下载cfssl签名工具
    # curl -fLo /usr/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    # curl -fLo /usr/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    /bin/cp -f cfssl_linux-amd64 /usr/bin/cfssl
    /bin/cp -f cfssljson_linux-amd64 /usr/bin/cfssljson
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
    "CN": "Self Signed Ca",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "SH",
            "O": "Netease",
            "ST": "SH",            
            "OU": "OT"
        }    ]
}
EOF

# 生成CA证书和私钥
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# 生成服务器端证书
cfssl print-defaults csr > server.json
cat > ca-csr.json <<EOF
{
    "CN": "Server",
    "hosts": [
        "192.168.31.200",
        "192.168.31.243",
        "192.168.31.246"
       ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "CN",
            "L": "SH",
            "ST": "SH"
        }
    ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare server

# 生成对等证书
cfssl print-defaults csr > member1.json
cat > ca-csr.json <<EOF
{
    "CN": "member1",
    "hosts": [
        "192.168.31.200",
        "192.168.31.243",
        "192.168.31.246"
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "CN",
            "L": "SH",
            "ST": "SH"
        }
    ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer member1.json | cfssljson -bare member1

# 生成客户端证书
cfssl print-defaults csr > client.json
cat > ca-csr.json <<EOF
{
    "CN": "Client",
    "hosts": [
        "192.168.31.200",
        "192.168.31.243",
        "192.168.31.246"
       ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "CN",
            "L": "SH",
            "ST": "SH"
        }
    ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client

# 最后校验证书
# openssl x509 -in ca.pem -text -noout
# openssl x509 -in server.pem -text -noout
# openssl x509 -in client.pem -text -noout

# 设置证书权限
chmod 666 /opt/cfssl/*

# 打包证书
cd /opt
tar zcvf cfssl.tar.gz cfssl/
  