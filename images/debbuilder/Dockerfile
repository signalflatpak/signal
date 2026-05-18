FROM debian:13
ENV USE_SYSTEM_FPM=true
ENV PATH=/opt/node/bin:$PATH
RUN apt-get update && \
    apt-get -qq install -y jq python3 gcc g++ make build-essential git git-lfs libffi-dev libssl-dev libglib2.0-0 libnss3 libatk1.0-0 libatk-bridge2.0-0 libx11-xcb1 libgdk-pixbuf-2.0-0 libgtk-3-0 libdrm2 libgbm1 ruby ruby-dev curl wget clang llvm lld clang-tools generate-ninja ninja-build pkg-config tcl wget libpixman-1-dev libcairo2-dev libpango1.0-dev && \
    gem install fpm && \
    apt-get autoclean && \
    rm -rf /var/cache/apt /var/lib/apt/lists

