FROM alpine

RUN apk update \
  && apk upgrade \
  && apk add --no-cache python py-pip bash jq \
  && pip install awscli  \
  && apk --purge -v del py-pip

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]