#!/bin/bash

function error_exit() {
    echo "$1"
    exit 1
}

if [ -z "$CLUSTER_NAME" ]; then
  error_exit "Cluster name not specified"
fi

# Make dfs.namenode.name.dir
NAME_DIR=$(hdfs getconf -confKey dfs.namenode.name.dir)
NAME_DIR=${NAME_DIR#"file://"}
if [ ! -d "$NAME_DIR" ]; then
  mkdir -p "${NAME_DIR}" || \
    error_exit "Could not create ${NAME_DIR}"
fi

# Make dfs.namenode.edits.dir
EDITS_DIR=$(hdfs getconf -confKey dfs.namenode.edits.dir)
EDITS_DIR=${EDITS_DIR#"file://"}
if [ ! -d "${EDITS_DIR}" ]; then
  mkdir -p "${EDITS_DIR}" || \
    error_exit "Could not create ${EDITS_DIR}"
fi

# Check if we need to format the namenode
if [[ ! -e "${NAME_DIR}/current/VERSION" || ! "$*" =~ "-persist" ]]; then
    # If it's not been formatted yet OR we don't want to keep the data from the previous run...format it
    echo "Deleting datanode data"
    DATANODE_DIR=$(hdfs getconf -confKey dfs.datanode.data.dir)
    DATANODE_DIR=${DATANODE_DIR#"file://"}
    pdsh -g datanode -S "rm -rf ${DATANODE_DIR}/*" || \
        error_exit "Could not clear out the datanode directories at ${DATANODE_DIR}"

    echo "Formatting namenode name directory: ${NAME_DIR}"
    hdfs namenode -format -force "$CLUSTER_NAME"
fi

hdfs namenode

tail -F /keep/me/running/if/namenode/startup/errors >/dev/null 2>&1
