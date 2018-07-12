FROM chromie/chromium-snapshot:latest

USER root
RUN apt-get update -qqy && apt-get install -y apt-transport-https dirmngr libssl-dev zlib1g-dev gcc

RUN apt-get update -qqy \
  && apt-get -qqy install \
      g++ libzmq3-dev \ 
      #libssl1.0-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

USER headless

WORKDIR /app
COPY run chromie

CMD ["./chromie"]
