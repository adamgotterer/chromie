FROM chromie/chromium-snapshot:latest

USER root
RUN apt-get update -qqy && apt-get install -y libevent-2.0-5 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

WORKDIR /app
COPY run chromie

USER headless

CMD ["./chromie"]
