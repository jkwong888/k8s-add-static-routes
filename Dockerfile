FROM alpine:latest

WORKDIR /root

RUN apk add --no-cache openssh-client bash git bc jq && \
      git clone https://github.com/JoeKuan/Network-Interfaces-Script.git && \
      apk del --no-cache git

ADD add-static-route.sh /root
RUN chmod a+x /root/add-static-route.sh

CMD [ "/root/add-static-route.sh" ]
