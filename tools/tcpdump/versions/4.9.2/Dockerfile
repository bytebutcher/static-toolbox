FROM alpine:3.9.2 AS builder

# Set the version of tcpdump
ENV TCPDUMP_VERSION=4.9.2

# Install necessary build dependencies
RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    automake \
    libpcap-dev \
    linux-headers \
    wget

# Set work directory
WORKDIR /opt

# Download and extract tcpdump source
RUN wget http://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz \
    && tar -xvf tcpdump-${TCPDUMP_VERSION}.tar.gz

# Build tcpdump statically
RUN cd tcpdump-${TCPDUMP_VERSION} \
    && CFLAGS="-static" LDFLAGS="-static" ./configure --without-crypto \
    && make LDFLAGS="-static"

# Copy the built 'tcpdump' binary to /output
RUN mkdir -p /output && cp /opt/tcpdump-${TCPDUMP_VERSION}/tcpdump /output/tcpdump

# Strip the binary to reduce size
RUN strip /output/tcpdump

# Create a minimal runtime image
FROM scratch
COPY --from=builder /output/tcpdump /tcpdump

# Set entrypoint
ENTRYPOINT ["/tcpdump"]
