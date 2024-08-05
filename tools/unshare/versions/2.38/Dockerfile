FROM alpine:3.18 AS builder

# Copy the version info file
ADD versions.env versions.env

# Copy the packages list
ADD packages.lst /packages.lst

# Add sources (used for caching downloaded files)
ADD src/ /src

# Copy the build script
ADD build.sh /build.sh

# Install packages and create lock file
RUN --mount=type=cache,target=/var/cache/apk apk update && \
    xargs -a /packages.lst apk add && \
    apk info -v > "/packages.lock"

# Run the individual steps of the build script
RUN /build.sh all

# Create a minimal runtime image
FROM busybox:latest
COPY --from=builder /packages.lock /packages.lock
COPY --from=builder /src /src
COPY --from=builder /output /output