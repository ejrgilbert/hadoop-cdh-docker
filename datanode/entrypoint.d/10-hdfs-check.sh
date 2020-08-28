#!/bin/bash

DATA_DIR=`echo $HDFS_CONF_dfs_datanode_data_dir | perl -pe 's#file://##'`
if [ ! -d ${} ]; then
  echo "Datanode data directory not found: $datadir"
  exit 2
fi
