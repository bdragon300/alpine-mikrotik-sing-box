#/bin/sh

set -e
set -x

[ -d bin ] || mkdir bin
mount -t tmpfs -o size=90M tmpfs bin
gzip -d sing-box.gz -c > bin/sing-box
chmod +x bin/sing-box
bin/sing-box -C /etc/sing-box run
