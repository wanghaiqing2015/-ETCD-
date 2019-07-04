etcdkeeper.exe -usetls -cacert cfssl/ca.pem -cert cfssl/client.pem -key cfssl/client-key.pem

http://127.0.0.1:8080/etcdkeeper/

export ETCDCTL_API=3   

etcdctl --endpoints=https://192.168.31.243:2379,https://192.168.31.244:2379,https://192.168.31.245:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem  put /name 666

etcdctl --endpoints=https://192.168.31.243:2379,https://192.168.31.244:2379,https://192.168.31.245:2379 --cacert=/opt/cfssl/ca.pem --cert=/opt/cfssl/client.pem --key=/opt/cfssl/client-key.pem  get / --prefix 