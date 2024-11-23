# Use a multi-stage build to keep the final image clean and small
FROM golang:1.22.4 as builder

# Set the working directory
WORKDIR /app

# Copy the go mod and sum files
COPY go.mod go.sum ./

# Download Go dependencies
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server .

# Use a small base image
FROM alpine:latest

# Install Docker CLI
RUN apk --no-cache add docker-cli

# Creating a non-root user within the advised UID/GID range for better security and predictability
RUN addgroup -g 10014 appgroup && \
    adduser -u 10014 -G appgroup -s /bin/sh -D appuser

# Copy the compiled Go server from the build container
COPY --from=builder /app/server /app/server

# Change ownership of the application files to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to the application directory as a work directory
WORKDIR /app

# Expose the port the server listens on
EXPOSE 8080

# Run the server as a non-root user with an approved UID
USER 10014
CMD ["./server"]
