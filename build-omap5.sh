#!/bin/bash

set -e

export PATH="/home/tools/arm-linux-gnueabihf/bin:/usr/local/bin:/usr/bin:/bin"

# XXX adjust this to flavor
armhf_compile="arm-linux-gnueabihf-"

kernel_dir=~/pyra/kernel
deploy_dir=~/pyra

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
		TARGET_PRODUCT=omap5uevm \
		KERNEL_COMPONENTS="srvkm" \
		"$@"
}

_make clean
_make

build_output=eurasia_km/eurasiacon/binary2_omap_linux_release/target/kbuild
modules=( pvrsrvkm.ko )

install_dir="tmp/lib/modules/$uname_r/extra"

mkdir -vp "$install_dir"
cp "${modules[@]/#/"$build_output/"}" "$install_dir"

package="sgx-omap5-modules-$uname_r"

mkdir -p tmp/DEBIAN
cat >tmp/DEBIAN/control <<END
Package: $package
Version: 1cross
Section: base
Priority: optional
Architecture: armhf
Depends: linux-image-$uname_r
Recommends: sgx-omap5-userspace-1.14.3699939
Maintainer: Matthijs van Duin <matthijsvanduin@gmail.com>
Description: sgx kernel modules for linux $uname_r for omap5
END

cat >tmp/DEBIAN/postinst <<END
#!/bin/sh
depmod $uname_r
END
chmod a+x tmp/DEBIAN/postinst

cat >tmp/DEBIAN/postrm <<END
#!/bin/sh
if [[ -d /lib/modules/$uname_r ]]; then
	depmod $uname_r
fi
END
chmod a+x tmp/DEBIAN/postrm

chmod -R g=rX,o=rX tmp


#echo ""
#echo "creating $deploy_dir/sgx-335x-$uname_r.tar.xz"
#tar cavf "$deploy_dir/sgx-335x-$uname_r.tar.xz" \
#	--owner=root --group=root --mode="g=rX,o=rX" \
#	"${modules[@]/#/"$install_dir/"}"

echo ""
echo "creating $deploy_dir/$package.deb"
fakeroot dpkg-deb --build tmp "$deploy_dir/$package.deb"

rm -rf tmp
