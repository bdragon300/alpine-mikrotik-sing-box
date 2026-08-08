# alpine-mikrotik-sing-box

Just plain Apline Docker image with compressed [sing-box](https://sing-box.sagernet.org/) executable inside and nothing else. Meant for [Mikrotik](https://mikrotik.com) devices. Image size is about 32Mb.

## Usage

### Prerequisites

First, check your Mikrotik is capable to run containers -- its CPU architecture should be arm32, arm64 or x86. See [products page](https://mikrotik.com/products/matrix).

Also, ensure you have installed a container [package](https://mikrotik.com/download/routeros) and enabled the containers (device may ask for a physical button press or reboot to confirm):

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

Upload your sing-box config file into router's `/vless_conf` directory and start the container:

```
/container start [find remote-image~"alpine-mikrotik-sing-box"]
```

## Manual image build

To build a Docker image with custom parameters use the `./build.sh` script (requires `curl`, `jq` and `docker`). See `./build.sh -h` for options help.

### Example

To build an image for a specific version of sing-box, run:

```bash
./build.sh -v 1.13.16 -O .
```

Script will build an image `alpine-mikrotik-sing-box-1.13.16-arm64-musl.tar` in current directory. Upload it to your Mikrotik and create a container:

```
/container add dns=8.8.8.8,8.8.4.4 file=alpine-mikrotik-sing-box-1.13.16-arm64-musl.tar interface=veth-sb layer-dir="" name=sing-box-client root-dir=/containers/sb shm-size=128.0MiB
```
