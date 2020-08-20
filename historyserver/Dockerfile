ARG VERSION
FROM dtspence/hadoop-base:$VERSION

HEALTHCHECK CMD curl -f http://$HOSTNAME:8188/ || exit 1

EXPOSE 8188

CMD ["mapred","historyserver"]
