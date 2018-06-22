 FROM node:8-slim

ARG DEBIAN_FRONTEND=noninteractive
ENV PUPPETEER_VERSION 1.5.0
ENV CHROXY_VERSION 0.3.2


RUN apt-get update -qqy \
  && apt-get -qqy install \
       unzip gnupg curl wget ca-certificates apt-transport-https \
       git ttf-wqy-zenhei g++ libzmq3-dev apt-utils vim  \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN curl https://dist.crystal-lang.org/apt/setup.sh | bash \
    && apt-get update -qqy \
    && apt-get install -qqy crystal


RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst ttf-freefont \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove -y curl \
    && rm -rf /src/*.deb

RUN npm i puppeteer@$PUPPETEER_VERSION

RUN useradd headless --create-home \
     && usermod -a -G sudo headless \
     && echo 'ALL ALL = NOPASSWD: ALL' >> /etc/sudoers \
     && echo 'headless:nopassword' | chpasswd

RUN mkdir /data \
    && chown -R headless:headless /data \
    && chown -R headless:headless /usr/bin/google-chrome \
    && chown -R headless:headless /usr/bin/google-chrome-unstable


USER headless

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /app

CMD ["mix", "run", "--no-halt"]
