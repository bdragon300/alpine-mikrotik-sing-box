FROM alpine:latest
# Create a directory without running mkdir to allow building images on other architectures
WORKDIR /etc/sing-box

WORKDIR /sing-box
COPY sing-box.gz .
COPY entrypoint.sh /

ENTRYPOINT "/entrypoint.sh"