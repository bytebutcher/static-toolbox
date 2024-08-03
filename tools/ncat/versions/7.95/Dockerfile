FROM alpine:3.14 AS builder

# Copy the packages list
ADD packages.lst /tmp/packages.lst

# Add source packages
ADD src/ /src

# Copy the build script
ADD build.sh /build.sh

# Run the individual steps of the build script
RUN --mount=type=cache,target=/var/cache/apk /build.sh install_packages
RUN /build.sh install_cross_compiler
RUN /build.sh build_openssl
RUN /build.sh build_zlib
RUN /build.sh build_libpcap
RUN /build.sh build_nmap

# Create a minimal runtime image
FROM scratch
COPY --from=builder /output/ncat /ncat

# Update entrypoint
ENTRYPOINT ["/ncat"]
