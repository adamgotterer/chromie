FROM chromie/headless-chrome-puppeteer:latest

USER root
RUN apt-get update -qqy && apt-get install -y apt-transport-https dirmngr libssl-dev zlib1g-dev gcc
RUN apt-key adv --keyserver hkp://keys.gnupg.net:80 --recv-keys 09617FD37CC06B54 \
    && echo "deb http://dist.crystal-lang.org/apt crystal main" > /etc/apt/sources.list.d/crystal.list

RUN apt-get update -qqy \
  && apt-get -qqy install \
      g++ libzmq3-dev libssl1.0-dev crystal \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

USER headless

WORKDIR /app
COPY run chromie

CMD ["./chromie"]
