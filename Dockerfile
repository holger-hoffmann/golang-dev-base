FROM alpine as builder

RUN apk add --no-cache curl
# Download the protobuffer compiler and make it available to be able to use
# in the golang container.
# The last three lines (the ones with chmod) are necessary to make the protoc
# folder available to everybody. The official release says to install it in
# your home directory and the files only give permissions to the user and
# group. We want to have it available for everybody, so we have to extend
# the (read and execute) permissions.
RUN curl --silent https://api.github.com/repos/protocolbuffers/protobuf/releases/latest \
    | grep -E "browser_download_url" \
    | grep linux-x86_64 \
    | cut -d '"' -f 4 \
    | xargs curl --silent --location --output protoc.zip && \
    mkdir -p /shared/protoc && \
    unzip protoc.zip -d /shared/protoc && \
    find /shared/protoc -type d -exec chmod a+rx {} + && \
    find /shared/protoc -type f -exec chmod a+r {} + && \
    find /shared/protoc/bin -type f -exec chmod a+x {} +

FROM golang:latest

COPY --from=builder  /shared/protoc /usr/local/protoc

# install the protobuffer plugins to generate go code and grpcurl
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go get github.com/fullstorydev/grpcurl/... && \
    go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

ENV PATH="/usr/local/protoc/bin:$PATH"
WORKDIR /go/src
