FROM debian:bullseye-slim AS builder

# Copy the version info file
ADD versions.env versions.env

# Copy the packages list
ADD packages.lst /packages.lst

# Add sources (used for caching downloaded files)
ADD src/ /src

# Copy the build script
ADD build.sh /build.sh

# Install packages and create lock file
RUN apt-get update && xargs -a /packages.lst apt-get install -y && \
    dpkg-query -W -f='${Package}=${Version}\n' > packages.lock

# Run the individual steps of the build script
RUN /build.sh all

# Create a minimal runtime image
FROM busybox:latest
COPY --from=builder /packages.lock /packages.lock
COPY --from=builder /src /src
COPY --from=builder /output /output
