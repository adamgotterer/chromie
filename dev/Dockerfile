FROM chromie/headless-chrome-puppeteer:v1.5.0

USER root

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 09617FD37CC06B54 \
    && echo "deb http://dist.crystal-lang.org/apt crystal main" > /etc/apt/sources.list.d/crystal.list

RUN apt-get update -qqy \
  && apt-get -qqy install gdb dsniff lsof net-tools crystal libevent-2.0-5 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

USER headless

WORKDIR /app

ENTRYPOINT ["dumb-init", "--"]
CMD ["crystal", "run", "run.cr"]
