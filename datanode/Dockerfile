ARG VERSION
FROM dtspence/hadoop-base:$VERSION

HEALTHCHECK CMD curl -f http://localhost:50075/ || exit 1

ENV HDFS_CONF_dfs_datanode_data_dir=file:///hadoop/dfs/data
RUN mkdir -p /hadoop/dfs/data && \
    chown -R hdfs:hdfs /hadoop/dfs/data

VOLUME /hadoop/dfs/data

EXPOSE 50075

CMD ["hdfs", "datanode"]
