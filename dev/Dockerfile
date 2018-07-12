FROM chromie/headless-chrome-puppeteer:v1.6.0

USER root

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 09617FD37CC06B54 \
    && echo "deb http://dist.crystal-lang.org/apt crystal main" > /etc/apt/sources.list.d/crystal.list

RUN apt-get update -qqy \
  && apt-get -qqy install crystal libevent-2.0-5 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

USER headless

WORKDIR /app

CMD ["crystal", "run", "run.cr"]
