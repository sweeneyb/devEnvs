


# Debugging
cloud-init logs are kept in /var/log/cloud-init.log and cloud-init-output.log.

To validate the schema
`cloud-init schema --system`


terraform plan -var-file=variables.tfvars
terraform apply -var-file=variables.tfvars
terraform destory -var-file=variables.tfvars

to see the tailscale key:
terraform output key


# TODO
# user isn't in the docker group
sudo usermod -aG docker $USER


# pulsar

gcp vm
zkip=$(ip -4 addr show ens4 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
externalip=100.76.108.93
virsh vm
zkip=$(ip -4 addr show enp1s0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
externalip=$(ip -4 addr show enp1s0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')


DETACHED
DETACHED=-d


## Zookeeper
mkdir -p data/zookeeper
mkdir data/zookeeper-config/
	
podman run $DETACHED -p 2181:2181 \
    -e metadataStoreUrl=zk:$zkip:2181 \
    -e cluster-name=cluster-a -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    -v $(pwd)/data/zookeeper:/pulsar/data/zookeeper:z \
    --name zookeeper \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/apply-config-from-env.py conf/zookeeper.conf && bin/generate-zookeeper-config.sh conf/zookeeper.conf && exec bin/pulsar zookeeper"

podman cp zookeeper:/pulsar/conf/ data/zookeeper-config/
### configure for cluster.  
this goes at the end of data/zookeeper-config/conf/zookeeper.conf
```
server.1=0.0.0.0:2888:3888
server.2=192.168.3.188:2888:3888
server.3=192.168.3.198:2888:3888
```
```
server.1=192.168.3.157:2888:3888
server.2=192.168.3.188:2888:3888
server.3=0.0.0.0:2888:3888
```

echo 3 > data/zookeeper/myid

podman run $DETACHED --rm -p 2181:2181 \
    -e metadataStoreUrl=zk:$zkip:2181 \
    -e cluster-name=cluster-a -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    -e ZOOKEEPER_SERVERS=192.168.3.157,192.168.3.188,192.168.3.198 \
    -v $(pwd)/data/zookeeper:/pulsar/data/zookeeper:z \
    -v $(pwd)/data/zookeeper-config/conf:/pulsar/conf:z \
    --name zookeeper \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/pulsar zookeeper"

podman run -it $DETACHED --rm -p 2181:2181 -p 3888:3888 -p 2888:2888 \
    -e metadataStoreUrl=zk:192.168.3.157:2181 \
    -e cluster-name=cluster-a -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    -v $(pwd)/data/zookeeper:/pulsar/data/zookeeper:z \
    -v $(pwd)/data/zookeeper-config/conf:/pulsar/conf:z \
    --name zookeeper \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/pulsar zookeeper"
	
	
podman run --rm \
    --name initialize-pulsar-cluster-metadata \
    docker.io/apachepulsar/pulsar-all:latest bash -c "bin/pulsar initialize-cluster-metadata \
--cluster cluster-a \
--zookeeper $zkip:2181 \
--configuration-store $zkip:2181 \
--web-service-url http://$externalip:8080 \
--broker-service-url pulsar://$externalip:6650"


## Pulsar
podman run --rm -e clusterName=cluster-a -p 3181:3181\
    -e zkServers=$zkip:2181 \
    -e metadataServiceUri=metadata-store:zk:$zkip:2181 \
    -v $(pwd)/data/bookkeeper:/pulsar/data/bookkeeper:z \
    --name bookie \
    -v $(pwd)/data/zookeeper-config/conf:/pulsar/conf:z \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/apply-config-from-env.py conf/bookkeeper.conf && exec bin/pulsar bookie"
	
podman run --rm -p 6650:6650 -p 8080:8080 \
    -e metadataStoreUrl=zk:$zkip:2181 \
    -e zookeeperServers=$zkip:2181 \
    -e clusterName=cluster-a \
    -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    --name broker \
    -v $(pwd)/data/zookeeper-config/conf:/pulsar/conf:z \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/apply-config-from-env.py conf/broker.conf && exec bin/pulsar broker"
	
podman pull docker.io/apachepulsar/pulsar-manager:latest
podman run -it --name pulsar_manager \
  -p 9527:9527 -p 7750:7750 \
  -e SPRING_CONFIGURATION_FILE=/pulsar-manager/pulsar-manager/application.properties \
  docker.io/apachepulsar/pulsar-manager:latest


CSRF_TOKEN=$(curl http://localhost:7750/pulsar-manager/csrf-token)
curl \
   -H 'X-XSRF-TOKEN: $CSRF_TOKEN' \
   -H 'Cookie: XSRF-TOKEN=$CSRF_TOKEN;' \
   -H "Content-Type: application/json" \
   -X PUT http://localhost:7750/pulsar-manager/users/superuser \
   -d '{"name": "admin", "password": "apachepulsar", "description": "test", "email": "username@test.org"}'