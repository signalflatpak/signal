#FROM ARCHSPECIFICVARIABLEVERSION/debian:bookworm
FROM docker.io/ARCHSPECIFICVARIABLEVERSION/debian:bookworm
RUN apt -qq update
#RUN apt -qq upgrade -y

# DEPS
RUN apt -qq install -y python3 gcc g++ make build-essential git git-lfs libffi-dev libssl-dev libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libgdk-pixbuf-2.0-0 libgtk-3-0 libdrm2 libgbm1 ruby ruby-dev curl wget clang llvm lld clang-tools generate-ninja ninja-build pkg-config tcl wget
RUN gem install fpm
ENV USE_SYSTEM_FPM=true
RUN mkdir -p /usr/include/ARCHSPECIFICVARIABLELONG-linux-gnu/
# pulled from https://raw.githubusercontent.com/node-ffi-napi/node-ffi-napi/master/deps/libffi/config/linux/ARCHSPECIFICVARIABLESHORT/fficonfig.h because its not in debian

# Buildscripts
COPY signal-buildscript.sh /
RUN chmod +x /signal-buildscript.sh

# Clone signal
RUN git clone https://github.com/signalapp/Signal-Desktop -b 7.27.x

# Sometimes crashes due to upstream running out of git-lfs download credit
RUN git clone https://github.com/signalapp/better-sqlite3.git || true
#COPY deps/sqlcipher.tar.gz /better-sqlite3/deps/


# NODE
# Goes last because docker build can't cache the tar.
# https://nodejs.org/dist/v14.15.5/
ENV NODE_VERSION=v20.15.1
RUN wget -q https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT.tar.gz -O /opt/node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT.tar.gz
COPY node.sums /opt/
# RUN shasum -c /opt/node.sums
RUN mkdir -p /opt/node
RUN cd /opt/; tar xf node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT.tar.gz
RUN mv /opt/node-${NODE_VERSION}-linux-ARCHSPECIFICVARIABLESHORT/* /opt/node/
#ENV PATH=/opt/node/bin:$PATH
ENV PATH=/Signal-Desktop/node_modules/.bin:/root/.cargo/bin:/opt/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
