ARG VERSION
FROM dtspence/hadoop-base:$VERSION

HEALTHCHECK CMD curl -f http://localhost:50070/ || exit 1

ENV HDFS_CONF_dfs_namenode_name_dir=file:///hadoop/dfs/name
RUN mkdir -p /hadoop/dfs/name && \
    chown hdfs:hdfs /hadoop/dfs/name

VOLUME /hadoop/dfs/name

EXPOSE 50070

ADD start-namenode.sh /start-namenode.sh
RUN chmod +x /start-namenode.sh

CMD [ "/start-namenode.sh" ]