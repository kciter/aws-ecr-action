FROM docker:19.03.4

RUN apk update \
  && apk upgrade \
  && apk add --no-cache --update python py-pip coreutils bash \
  && rm -rf /var/cache/apk/* \
  && pip install awscli==1.18.95 \
  && apk --purge -v del py-pip

ADD entrypoint.sh /entrypoint.sh

RUN ["chmod", "+x", "/entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]
