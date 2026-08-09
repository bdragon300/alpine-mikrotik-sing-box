# alpine-mikrotik-sing-box

A plain Alpine Docker image with a compressed [sing-box](https://sing-box.sagernet.org/) executable inside and nothing else. Intended for [MikroTik](https://mikrotik.com) devices.

Optimized for low disk usage on the router at the cost of RAM.

## Usage

### Prerequisites

First, check that your MikroTik device can run containers — its CPU architecture must be ARM32, ARM64, or x86. See the [products page](https://mikrotik.com/products/matrix).

Also, make sure the container [package](https://mikrotik.com/download/routeros) is installed and containers are enabled (the device may ask for a physical button press or a reboot to confirm):

```
/system device-mode update container=yes
```

Finally, set up the container registry:

```
/container/config set registry-url=https://registry-1.docker.io tmpdir=tmp1
```

### Run the container

```
/interface/veth add name=veth-vless address=192.168.254.2/24 gateway=192.168.254.1
/container mounts add dst=/etc/sing-box list=VLESS mode=ro,noexec src=/vless_conf
/container/add remote-image=falconerity/alpine-mikrotik-sing-box:latest interface=veth-vless root-dir=containers/vless mountlists=VLESS start-on-boot=yes logging=no dns=1.1.1.1,8.8.8.8
```

Upload your sing-box configuration file(s) to the router's `/vless_conf` directory, then start the container:

```
/container start [find remote-image~"alpine-mikrotik-sing-box"]
```

## Manual image build

To build a Docker image with custom parameters, use the `./build.sh` script (requires `curl`, `jq`, and `docker`). Run `./build.sh -h` to see the available options.

### Example

To build an image for a specific version of sing-box, run:

```bash
./build.sh -v 1.13.16 -O .
```

The script builds the image `alpine-mikrotik-sing-box-1.13.16-arm64-musl.tar` in the current directory. Upload it to your MikroTik device and create a container:

```
/container add file=alpine-mikrotik-sing-box-1.13.16-arm64-musl.tar name=sing-box-client interface=veth-vless root-dir=/containers/vless mountlists=VLESS start-on-boot=yes logging=no dns=8.8.8.8,8.8.4.4
```
