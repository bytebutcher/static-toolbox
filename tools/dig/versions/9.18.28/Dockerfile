# Set the version of BIND (which includes dig)
ARG BIND_VERSION=9.18.28

# Build stage
FROM alpine:3.18 AS builder

# Set build arg
ARG BIND_VERSION

# Set work directory
WORKDIR /opt

RUN apk add -U alpine-sdk \
    && curl https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERISON}.tar.xz | tar xJ \
    && cd bind-${BIND_VERSION} \
    && CFLAGS="-static" ./configure --without-openssl --disable-symtable \
    && make \
    && strip ./bin/dig/dig \
    && apk del alpine-sdk \
    && rm -rf bind-${BIND_VERSION}/


# Create a minimal runtime image
FROM scratch

# Set build arg
ARG BIND_VERSION

# Copy the built 'dig' binary from the builder stage
COPY --from=builder /opt/bind-${BIND_VERSION}/bin/dig/dig /dig

# Set entrypoint
ENTRYPOINT ["/dig"]
