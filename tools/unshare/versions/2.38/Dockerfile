# Set the version of util-linux
ARG UTIL_LINUX_VERSION=2.38

# Build stage
FROM alpine:3.18 AS builder

# Use build argument
ARG UTIL_LINUX_VERSION

# Install necessary build dependencies
RUN apk add --no-cache \
    build-base \
    linux-headers \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    xz \
    curl

# Set work directory
WORKDIR /opt

# Download and extract util-linux source
RUN curl -LO https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VERSION}/util-linux-${UTIL_LINUX_VERSION}.tar.xz \
    && tar xf util-linux-${UTIL_LINUX_VERSION}.tar.xz

# Build unshare statically
RUN cd util-linux-${UTIL_LINUX_VERSION} \
    && ./configure LDFLAGS="-static" --disable-shared --without-python --disable-all-programs --enable-unshare \
    && make \
    && strip ./unshare

# Create a minimal runtime image
FROM scratch

# Use build argument
ARG UTIL_LINUX_VERSION

# Copy the built 'unshare' binary from the builder stage
COPY --from=builder /opt/util-linux-${UTIL_LINUX_VERSION}/unshare /unshare

# Set entrypoint
ENTRYPOINT ["/unshare"]
