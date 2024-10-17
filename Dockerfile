#FROM ARCHSPECIFICVARIABLEVERSION/debian:bookworm
FROM docker.io/ARCHSPECIFICVARIABLEVERSION/debian:bookworm
RUN apt -qq update

# DEPS
RUN apt -qq install -y python3 gcc g++ make build-essential git git-lfs libffi-dev libssl-dev libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libgdk-pixbuf-2.0-0 libgtk-3-0 libdrm2 libgbm1 ruby ruby-dev curl wget clang llvm lld clang-tools generate-ninja ninja-build pkg-config tcl wget
RUN gem install fpm
ENV USE_SYSTEM_FPM=true

# Clone signal
RUN git clone https://github.com/signalapp/Signal-Desktop -b 7.29.x

# Sometimes crashes due to upstream running out of git-lfs download credit
RUN git clone https://github.com/signalapp/better-sqlite3.git || true


# NODE
# Goes last because docker build can't cache the tar.
# https://nodejs.org/dist/v14.15.5/
ENV NODE_VERSION=v20.17.0
RUN wget -q https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT.tar.gz -O /opt/node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT.tar.gz
RUN mkdir -p /opt/node
RUN cd /opt/; tar xf node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT.tar.gz
RUN mv /opt/node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT/* /opt/node/
