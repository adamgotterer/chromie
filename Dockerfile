FROM chromie/chromium-snapshot:latest

USER root
RUN apt-get update -qqy && apt-get install -y libevent-2.0-5 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

WORKDIR /app
COPY run chromie

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

USER headless

ENTRYPOINT ["dumb-init", "--"]
CMD ["./chromie"]
