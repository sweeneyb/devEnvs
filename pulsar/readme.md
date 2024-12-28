


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


zkip=(ip -4 addr show ens4 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
tsip=100.76.108.93
	
podman run -p 2181:2181 \
    -e metadataStoreUrl=zk:10.142.0.2:2181 \
    -e cluster-name=cluster-a -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    -v $(pwd)/data/zookeeper:/pulsar/data/zookeeper \
    --name zookeeper \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/apply-config-from-env.py conf/zookeeper.conf && bin/generate-zookeeper-config.sh conf/zookeeper.conf && exec bin/pulsar zookeeper"
	
	
podman run \
    --name initialize-pulsar-cluster-metadata \
    docker.io/apachepulsar/pulsar-all:latest bash -c "bin/pulsar initialize-cluster-metadata \
--cluster cluster-a \
--zookeeper 10.142.0.2:2181 \
--configuration-store 10.142.0.2:2181 \
--web-service-url http://100.76.108.93:8080 \
--broker-service-url pulsar://100.76.108.93:6650"


podman run -e clusterName=cluster-a \
    -e zkServers=10.142.0.2:2181 \
    -e metadataServiceUri=metadata-store:zk:10.142.0.2:2181 \
    -v $(pwd)/data/bookkeeper:/pulsar/data/bookkeeper \
    --name bookie \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/apply-config-from-env.py conf/bookkeeper.conf && exec bin/pulsar bookie"
	
podman run -p 6650:6650 -p 8080:8080 \
    -e metadataStoreUrl=zk:10.142.0.2:2181 \
    -e zookeeperServers=10.142.0.2:2181 \
    -e clusterName=cluster-a \
    -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    --name broker \
    docker.io/apachepulsar/pulsar-all:latest \
    bash -c "bin/apply-config-from-env.py conf/broker.conf && exec bin/pulsar broker"
	
podman pull docker.io/apachepulsar/pulsar-manager:latest
podman run -it \
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