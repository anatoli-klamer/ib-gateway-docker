
#
# Setup Stage: install apps
#
# This is a dedicated stage so that donwload archives don't end up on 
# production image and consume unnecessary space.
#

FROM ubuntu:22.04 as setup
ENV VERSION=10.23.2b
ENV IB_GATEWAY_VERSION=10.23.2b
ENV IBC_VERSION=3.18.0
ENV IB_GATEWAY_RELEASE_CHANNEL=standalone
ENV IB_GATEWAY_RELEASE_VERSION=stable

# Prepare system
RUN apt-get update -y
RUN apt-get install --no-install-recommends --yes \
  curl \
  ca-certificates \
  unzip

# Install IB Gateway
WORKDIR /tmp/setup
RUN curl -sSL https://download2.interactivebrokers.com/installers/ibgateway/${IB_GATEWAY_RELEASE_VERSION}-${IB_GATEWAY_RELEASE_CHANNEL}/ibgateway-${IB_GATEWAY_RELEASE_VERSION}-${IB_GATEWAY_RELEASE_CHANNEL}-linux-x64.sh --output ibgateway-${IB_GATEWAY_VERSION}.sh
RUN chmod a+x ./ibgateway-${IB_GATEWAY_VERSION}.sh
RUN ./ibgateway-${IB_GATEWAY_VERSION}.sh -q -dir /root/Jts/ibgateway/${IB_GATEWAY_VERSION}
COPY ./config/ibgateway/jts.ini /root/Jts/jts.ini

# Install IBC
RUN curl -sSL https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip --output IBCLinux-${IBC_VERSION}.zip
RUN mkdir /root/ibc
RUN unzip ./IBCLinux-${IBC_VERSION}.zip -d /root/ibc
RUN chmod -R u+x /root/ibc/*.sh 
RUN chmod -R u+x /root/ibc/scripts/*.sh
COPY ./config/ibc/config.ini.tmpl /root/ibc/config.ini.tmpl

# Copy scripts
COPY ./scripts /root/scripts

#
# Build Stage: build production image
#

FROM ubuntu:22.04

ENV IB_GATEWAY_VERSION=$VERSION

WORKDIR /root

# Prepare system
RUN apt-get update -y
RUN apt-get install --no-install-recommends --yes \
  gettext \
  xvfb \
  libxslt-dev \
  libxrender1 \
  libxtst6 \
  libxi6 \
  libgtk2.0-bin \
  socat \
  x11vnc \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Copy files
COPY --from=setup /root/ .
RUN chmod a+x /root/scripts/*.sh
COPY --from=setup /usr/local/i4j_jres/ /usr/local/i4j_jres

# IBC env vars
ENV TWS_MAJOR_VRSN ${IB_GATEWAY_VERSION}
ENV TWS_PATH /root/Jts
ENV IBC_PATH /root/ibc
ENV IBC_INI /root/ibc/config.ini
ENV TWOFA_TIMEOUT_ACTION exit

# Start run script
CMD ["/root/scripts/run.sh"]
