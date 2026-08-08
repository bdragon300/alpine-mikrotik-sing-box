#!/bin/sh

set -eo pipefail

BUILDDIR=./build
DOCKERDIR=./docker

DOCKER_IMAGE=falconerity/alpine-mikrotik-sing-box
TARFILE_PREFIX="alpine-mikrotik-sing-box"
ARCH=arm64
VARIANT=musl

while getopts ":v:a:V:p:t:O:B:cLh" flag; do
    case "${flag}" in
        v) VERSION="$OPTARG" ;;
        a) ARCH="$OPTARG" ;;
        V) VARIANT="$OPTARG" ;;
        p) DOCKER_PLATFORM="$OPTARG" ;;
        t) DOCKER_TAG="$OPTARG" ;;
        O) OUTDIR=1 ;;
        B) BUILDDIR="$OPTARG" ;;
        c) CLEAN=1 ;;
        L) LATEST_VERSION=1 ;;
        h) 
            cat <<EOF
Usage: $0 [-v VERSION] [-a ARCH] [-V VARIANT] [-p DOCKER_PLATFORM] [-t DOCKER_TAG] [-O OUTDIR] [-B BUILDDIR] [-c] [-L] [-h]
Download a sing-box release and build a Docker image

Options:
  -v VERSION
        sing-box version to use. Default is the latest version
  -a ARCH
        sing-box release machine architecture to use. Possible values are: "arm64", "armv5", "armv6", "armv7", "386", "amd64". Default is "$ARCH"
  -V VARIANT
        sing-box release variant to use. Possible values are: "glibc", "musl" and "". Default is "$VARIANT"
  -p DOCKER_PLATFORM
        target Docker platform (machine architecture). By default, depends on sing-box architecture.
  -t DOCKER_TAG
        additionally tag the Docker image
  -O OUTDIR
        additionally save an image into as tar file into specified directory
  -B BUILDDIR
        temporary build directory. Default is "$BUILDDIR"
  -c
        clean after build
  -L
        print the latest sing-box release version and exit
  -h
        display this help
EOF
            exit 0
            ;;
        ?)
            echo "Invalid option: -${OPTARG}. Use -h to show help" >&2
            exit 1
            ;;
    esac
done

SINGBOX_FILENAME_REGEX="sing-box-[0-9.]+-linux-${ARCH}-${VARIANT}.tar.gz"
GH_API_URL="https://api.github.com/repos/SagerNet/sing-box/releases"

if [ -n "$LATEST_VERSION" ]; then
    curl -fsS "$GH_API_URL/latest" | jq -r "first(.assets[] | select(.name | test(\"${SINGBOX_FILENAME_REGEX}\")) | .browser_download_url)" | grep -Po "(?<=sing-box-)[0-9.]+"
    exit 0
fi

echo -n "Docker platform: "
if [ -z "$DOCKER_PLATFORM" ]; then
    case "$ARCH" in
        arm64) DOCKER_PLATFORM=linux/arm64/v8 ;;
        armv5) DOCKER_PLATFORM=linux/arm/v5 ;;
        armv6) DOCKER_PLATFORM=linux/arm/v6 ;;
        armv7) DOCKER_PLATFORM=linux/arm/v7 ;;
        386) DOCKER_PLATFORM=linux/386 ;;
        amd64) DOCKER_PLATFORM=linux/amd64 ;;
        *)
            echo "cannot determine for architecture $ARCH. Check if the architecture is correct or set the platform manually in -p option. See -h for help"
            exit 1
            ;;
    esac
fi
echo "$DOCKER_PLATFORM"

echo "Build dir: $BUILDDIR"
[ ! -d "$BUILDDIR" ] && mkdir -p "$BUILDDIR"

if [ -n "$VERSION" ]; then
    GH_API_URL="$GH_API_URL/tags/v$VERSION"
else
    GH_API_URL="$GH_API_URL/latest"
fi

echo "Requesting $GH_API_URL"
URL=$(curl -fsS "$GH_API_URL" | jq -r "first(.assets[] | select(.name | test(\"${SINGBOX_FILENAME_REGEX}\")) | .browser_download_url)")
if [ -z "$URL" ]; then
    echo "$VERSION/$ARCH/$VARIANT file not found in sing-box releases" >&2
    exit 1
fi

[ -z "$VERSION" ] && VERSION=$(echo $URL | grep -Po "(?<=sing-box-)[0-9.]+")
echo "Sing-box release: $VERSION/$ARCH/$VARIANT"

echo "Downloading archive $URL..."
SINGBOX_FILENAME=$(basename "$URL")
curl -Lo "$BUILDDIR/$SINGBOX_FILENAME" "$URL"

echo "Extracting archive..."
ARCHIVEDIR="${BUILDDIR}/sing-box-${VERSION}-${ARCH}-${VARIANT}"
[ ! -d "$ARCHIVEDIR" ] && mkdir -p "$ARCHIVEDIR"
tar xvf "$BUILDDIR/$SINGBOX_FILENAME" -C "$ARCHIVEDIR" --strip-components=1

echo "Preparing the building..."
gzip -1 -c "${ARCHIVEDIR}/sing-box" > "${BUILDDIR}/sing-box.gz"
cp $DOCKERDIR/* "$BUILDDIR"

echo "Building ${DOCKER_IMAGE}:${VERSION}..."
docker buildx build -f $BUILDDIR/Dockerfile --no-cache --progress=plain --platform $DOCKER_PLATFORM --output=type=docker --tag ${DOCKER_IMAGE}:${VERSION} ${BUILDDIR}/

if [ -n "$DOCKER_TAG" ]; then
    echo "Tagging ${DOCKER_IMAGE}:${VERSION} as ${DOCKER_IMAGE}:${DOCKER_TAG}"
    docker tag ${DOCKER_IMAGE}:${VERSION} ${DOCKER_IMAGE}:${DOCKER_TAG}
fi
if [ -n "$OUTDIR" ]; then
    TARFILE="${TARFILE_PREFIX}-${VERSION}-${ARCH}-${VARIANT}.tar"
    echo "Saving image ${DOCKER_IMAGE}:${VERSION} into $TARFILE..."
    docker image save -o "$TARFILE" ${DOCKER_IMAGE}:${VERSION}
fi
if [ -n "$CLEAN" ]; then
    echo "Cleaning up $BUILDDIR"
    rm -r "$BUILDDIR"
fi

echo "Done"