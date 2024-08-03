FROM debian:bullseye-slim AS builder

# Set the version of procps-ng
ENV PROCPS_VERSION=4.0.4

# Install necessary build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    make \
    automake \
    autoconf \
    libtool \
    gettext \
    autopoint \
    pkg-config \
    libncurses5-dev \
    wget \
    git \
    file

# Set work directory
WORKDIR /opt

# Download and extract procps-ng source
RUN wget https://gitlab.com/procps-ng/procps/-/archive/v${PROCPS_VERSION}/procps-v${PROCPS_VERSION}.tar.gz \
    && tar xzf procps-v${PROCPS_VERSION}.tar.gz

# Build procps-ng statically
RUN cd procps-v${PROCPS_VERSION} \
    && ./autogen.sh \
    && CFLAGS="-static" LDFLAGS="-static" ./configure --disable-shared --enable-static \
    && make SHARED=0 CC='gcc -static'

# Copy the built 'ps' binary to /output (if it exists)
RUN mkdir -p /output && cp /opt/procps-v${PROCPS_VERSION}/src/ps/pscommand /output/ps

# Strip the binary to reduce size
RUN strip /output/ps

# Create a minimal runtime image
FROM scratch
COPY --from=builder /output/ps /ps

# Set entrypoint
ENTRYPOINT ["/ps"]
