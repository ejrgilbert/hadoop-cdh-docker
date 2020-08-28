#!/bin/bash

APP_LOG_DIR=$(xmllint --xpath 'string(//configuration/property[name="yarn.nodemanager.remote-app-log-dir"]/value)' "${HADOOP_CONF_DIR}/yarn-site.xml")

if ! hdfs dfs -mkdir "${APP_LOG_DIR}"; then
    echo "Failed to create the app-log-dir: ${APP_LOG_DIR}"
    exit 1
fi
