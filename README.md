# alpine-mikrotik-sing-box

[![Docker Image Version](https://img.shields.io/docker/v/falconerity/alpine-mikrotik-sing-box?sort=semver)](https://hub.docker.com/r/falconerity/alpine-mikrotik-sing-box)

A plain Alpine Docker image with a compressed [sing-box](https://sing-box.sagernet.org/) executable inside and nothing else. Intended for [MikroTik](https://mikrotik.com) devices. Optimized for low disk usage on the router at the cost of RAM.

The image is rebuilt automatically for each new stable sing-box release.

## Usage

### Prerequisites

First, check that your MikroTik device can run containers — its CPU architecture must be ARM32 (ARMv7), ARM64, or x86. See the [products page](https://mikrotik.com/products/matrix).

Also, make sure the container [package](https://mikrotik.com/download/routeros) is installed and containers are enabled (the device may ask for a physical button press or a reboot to confirm):

```routeros
/system/device-mode update container=yes
```

Finally, set up the container registry:

```routeros
/container/config set registry-url=https://registry-1.docker.io tmpdir=tmp1
```

### Run the container

```routeros
/interface/veth add name=veth-vless address=192.168.254.2/24 gateway=192.168.254.1
/container/mounts add dst=/etc/sing-box list=VLESS mode=ro,noexec src=/vless_conf
/container add remote-image=falconerity/alpine-mikrotik-sing-box:latest interface=veth-vless root-dir=/containers/vless mountlists=VLESS start-on-boot=yes logging=no dns=1.1.1.1,8.8.8.8
```

Upload your sing-box configuration files to the router's `/vless_conf` directory, then start the container:

```routeros
/container start [find remote-image~"alpine-mikrotik-sing-box"]
```

## Manual image build

To build a Docker image with custom parameters, use the `build.sh` script (requires `curl`, `jq`, and `docker`). Run `./build.sh -h` to see the available options.

### Example

To build an image for a specific version of sing-box targeting the `armv7` architecture, run:

```bash
./build.sh -v 1.13.16 -a armv7 -O .
```

The script builds the image and saves it to `alpine-mikrotik-sing-box-1.13.16-armv7-musl.tar` in the current directory. Upload it to your MikroTik device and create a container:

```routeros
/container add file=alpine-mikrotik-sing-box-1.13.16-armv7-musl.tar name=sing-box-client interface=veth-vless root-dir=/containers/vless mountlists=VLESS start-on-boot=yes logging=no dns=8.8.8.8,8.8.4.4
```
