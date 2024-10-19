FROM alpine:3.20
VOLUME /mnt/dest

RUN apk --update --no-cache add \
	cifs-utils \
	rsync

ADD ./do_onetime_pull.sh /do_onetime_pull.sh

ENTRYPOINT ["/do_onetime_pull.sh"]
CMD []
