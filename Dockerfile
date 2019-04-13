FROM maven:3-jdk-11

# Ajout des package nécessaire pour build-jre.sh
RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        advancecomp \
        binutils \
        bsdtar \
        gcc \
        libz-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV GRAALVM_HOME=/usr/share/graalvm

ARG GRAALVM_VERSION=1.0.0-rc15

RUN mkdir -p "${GRAALVM_HOME}" \
    && curl -L \
        https://github.com/oracle/graal/releases/download/vm-${GRAALVM_VERSION}/graalvm-ce-${GRAALVM_VERSION}-linux-amd64.tar.gz \
        -o /tmp/graalvm.tar.gz \
    && bsdtar -xvf /tmp/graalvm.tar.gz -C "${GRAALVM_HOME}" --strip-components=1 \
    && rm -rf /tmp/graalvm.tar.gz

COPY ./build-jre.sh /
COPY ./setupMavenProxy.sh /
