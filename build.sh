#!/bin/bash

set -e

# XXX adjust this to flavor
kernel_work=~/rcn/kernel	# your checkout of rcn-ee kernel build repo
armhf_compile="ccache arm-linux-gnueabihf-"

kernel_dir="$kernel_work/KERNEL"
deploy_dir="$kernel_work/deploy"

if [[ ! -f "$kernel_dir/include/generated/utsrelease.h" ]]; then
	echo "Not found: $kernel_dir/include/generated/utsrelease.h" >&2
	exit 1
fi
uname_r="$(grep -oP '(?<=")[^\s"]+(?=")' \
		"$kernel_dir/include/generated/utsrelease.h")"

_make() {
	make -C eurasia_km/eurasiacon/build/linux2/omap_linux \
		ARCH=arm CROSS_COMPILE="$armhf_compile" \
		KERNELDIR="$kernel_dir" \
		TARGET_PRODUCT=ti335x \
		KERNEL_COMPONENTS="srvkm" \
		"$@"
}

_make clean
_make

build_output=eurasia_km/eurasiacon/binary2_omap_linux_release/target/kbuild
modules=( pvrsrvkm.ko )

install_dir="lib/modules/$uname_r/extra"

mkdir -vp "$install_dir"
cp "${modules[@]/#/"$build_output/"}" "$install_dir"

echo ""
echo "creating $deploy_dir/sgx-335x-$uname_r.tar.xz"
tar cavf "$deploy_dir/sgx-335x-$uname_r.tar.xz" \
	--owner=root --group=root --mode="g=rX,o=rX" \
	"${modules[@]/#/"$install_dir/"}"
