#!/bin/bash

set -eo pipefail

source /opt/scripts/configure-lib.sh
source /opt/scripts/hdfs-lib.sh

# Set some sensible defaults
export CORE_CONF_fs_defaultFS=${CORE_CONF_fs_defaultFS:-hdfs://$(hostname -f):8020}

configure /etc/hadoop/conf/core-site.xml core CORE_CONF
configure /etc/hadoop/conf/hdfs-site.xml hdfs HDFS_CONF
configure /etc/hadoop/conf/mapred-site.xml mapred MAPRED_CONF
configure /etc/hadoop/conf/yarn-site.xml yarn YARN_CONF
configure /etc/hadoop/conf/httpfs-site.xml httpfs HTTPFS_CONF
configure /etc/hadoop/conf/kms-site.xml kms KMS_CONF

if [ "$MULTIHOMED_NETWORK" = "1" ]; then
    echo "Configuring for multihomed network"

    # HDFS
    add_property /etc/hadoop/conf/hdfs-site.xml dfs.namenode.rpc-bind-host 0.0.0.0
    add_property /etc/hadoop/conf/hdfs-site.xml dfs.namenode.servicerpc-bind-host 0.0.0.0
    add_property /etc/hadoop/conf/hdfs-site.xml dfs.namenode.http-bind-host 0.0.0.0
    add_property /etc/hadoop/conf/hdfs-site.xml dfs.namenode.https-bind-host 0.0.0.0
    add_property /etc/hadoop/conf/hdfs-site.xml dfs.client.use.datanode.hostname true
    add_property /etc/hadoop/conf/hdfs-site.xml dfs.datanode.use.datanode.hostname true

    # YARN
    add_property /etc/hadoop/conf/yarn-site.xml yarn.resourcemanager.bind-host 0.0.0.0
    add_property /etc/hadoop/conf/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
    add_property /etc/hadoop/conf/yarn-site.xml yarn.nodemanager.bind-host 0.0.0.0
    add_property /etc/hadoop/conf/yarn-site.xml yarn.timeline-service.bind-host 0.0.0.0

    # MAPRED
    add_property /etc/hadoop/conf/mapred-site.xml yarn.nodemanager.bind-host 0.0.0.0
fi

if [ -n "$GANGLIA_HOST" ]; then
    mv /etc/hadoop/conf/hadoop-metrics.properties /etc/hadoop/conf/hadoop-metrics.properties.orig
    mv /etc/hadoop/conf/hadoop-metrics2.properties /etc/hadoop/conf/hadoop-metrics2.properties.orig

    for module in mapred jvm rpc ugi; do
        echo "$module.class=org.apache.hadoop.metrics.ganglia.GangliaContext31"
        echo "$module.period=10"
        echo "$module.servers=$GANGLIA_HOST:8649"
    done > /etc/hadoop/conf/hadoop-metrics.properties
    
    for module in namenode datanode resourcemanager nodemanager mrappmaster jobhistoryserver; do
        echo "$module.sink.ganglia.class=org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31"
        echo "$module.sink.ganglia.period=10"
        echo "$module.sink.ganglia.supportsparse=true"
        echo "$module.sink.ganglia.slope=jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both"
        echo "$module.sink.ganglia.dmax=jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40"
        echo "$module.sink.ganglia.servers=$GANGLIA_HOST:8649"
    done > /etc/hadoop/conf/hadoop-metrics2.properties
fi

function wait_for_it()
{
    local serviceport=$1
    local service=${serviceport%%:*}
    local port=${serviceport#*:}
    local retry_seconds=5
    local max_try=100
    (( i = 1 ))

    until curl -sf "$service:$port" >/dev/null 2>&1; do
      echo "[$i/$max_try] check for ${service}:${port}..."
      echo "[$i/$max_try] ${service}:${port} is not available yet"
      if (( i == max_try )); then
        echo "[$i/$max_try] ${service}:${port} is still not available; giving up after ${max_try} tries. :/"
        exit 1
      fi

      echo "[$i/$max_try] try in ${retry_seconds}s once again ..."
      (( i++ ))
      sleep $retry_seconds
    done
    echo "[$i/$max_try] $service:${port} is available."
}

# Execute scripts in the directory on entry

DIR=/entrypoint.d
read -r -a to_check_status <<< "${SERVICE_PRECONDITION}"

if [[ -d "$DIR" ]]; then
  echo "Running run-parts ..."
  /bin/run-parts "$DIR"
fi

echo "${to_check_status[*]}"
for i in "${to_check_status[@]}"
do
    wait_for_it "${i}"
done

echo "after waiting"
if [ -z "$1" ]; then
  echo "Specify command to run."
  exit 1
fi

exec "$@"
