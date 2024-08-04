# Set the version
ARG NAME="tool"
ARG VERSION=0.0.1

# Build stage
FROM alpine:3.18 AS builder

# Set build args
ARG NAME
ARG VERSION

# Add build script
ADD ./build.sh /build.sh 

# Set work directory
WORKDIR /

# Install necessary packages
RUN apk add --no-cache alpine-sdk xz curl

# Run build script
RUN build.sh all $VERSION

# Create a minimal runtime image
FROM scratch

# Set build args
ARG NAME
ARG VERSION

# Copy the built binary from the builder stage
COPY --from=builder /output/${NAME}-${VERSION}/${NAME} /${NAME}

# Set entrypoint
ENTRYPOINT ["/${NAME}"]
