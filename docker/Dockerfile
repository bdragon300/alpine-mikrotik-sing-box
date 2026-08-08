FROM --platform=linux/arm64/v8 alpine:latest
# Create directory without running mkdir to allow building on other architectures
WORKDIR /etc/sing-box

WORKDIR /sing-box
COPY sing-box.gz .
COPY entrypoint.sh /


ENTRYPOINT "/entrypoint.sh"