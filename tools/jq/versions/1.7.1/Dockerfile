# Define build argument
ARG JQ_VERSION=1.7.1

# Build stage
FROM alpine:3.18 AS builder

# Use the build argument
ARG JQ_VERSION

# Install necessary build dependencies
RUN apk add --no-cache \
    build-base \
    autoconf \
    automake \
    libtool \
    wget

# Set work directory
WORKDIR /opt

# Download and extract jq source
RUN wget https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz \
    && tar xzf jq-${JQ_VERSION}.tar.gz

# Build jq statically
RUN cd jq-${JQ_VERSION} \
    && autoreconf -fi \
    && ./configure --disable-shared --enable-static --disable-maintainer-mode \
    && make LDFLAGS=-all-static \
    && strip jq

# Create a minimal runtime image
FROM scratch

# Use the build argument
ARG JQ_VERSION

# Copy the built 'jq' binary from the builder stage
COPY --from=builder /opt/jq-${JQ_VERSION}/jq /output/jq

# Set entrypoint
ENTRYPOINT ["/output/jq"]
