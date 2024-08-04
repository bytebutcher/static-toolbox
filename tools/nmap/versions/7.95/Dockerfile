FROM alpine:3.14 AS builder

# Copy the version info file
ADD versions.env versions.env

# Copy the packages list
ADD packages.lst /tmp/packages.lst

# Add sources (if any)
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
COPY --from=builder /output/nmap /output/nmap
COPY --from=builder /output/ncat /output/ncat
COPY --from=builder /output/nping /output/nping

# Update entrypoint
ENTRYPOINT ["/nmap"]
