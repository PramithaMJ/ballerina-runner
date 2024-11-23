# Use a multi-stage build to keep the final image clean and small
FROM golang:1.18 as builder

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

# Copy the compiled Go server from the build container
COPY --from=builder /app/server .

# Expose the port the server listens on
EXPOSE 8080

# Run the server
CMD ["./server"]
